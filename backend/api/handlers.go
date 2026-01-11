package api

import (
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/anthonyhana04/Delta-Hacks-2026/backend/database"
	"github.com/anthonyhana04/Delta-Hacks-2026/backend/models"
	"github.com/anthonyhana04/Delta-Hacks-2026/backend/services"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Controller struct {
	SourceS3      *services.S3Service // For original images
	GeneratedS3   *services.S3Service // For AI output
	AIService     *services.AIService
	KeyGenService *services.KeyGenService
	DB            *gorm.DB
}

func NewController() *Controller {
	// 1. Source Bucket
	srcBucket := os.Getenv("AWS_BUCKET_NAME")
	if srcBucket == "" {
		srcBucket = "lava-banana"
	}

	// 2. Generated Bucket
	genBucket := os.Getenv("AWS_GENERATED_BUCKET_NAME")
	if genBucket == "" {
		genBucket = "lava-banana-output"
	} // Default

	region := os.Getenv("AWS_REGION")
	if region == "" {
		region = "us-east-1"
	}

	srcS3, _ := services.NewS3Service(region, srcBucket)
	genS3, _ := services.NewS3Service(region, genBucket)

	db := database.InitDB()

	apiKey := os.Getenv("GEMINI_API_KEY")
	aiSvc, _ := services.NewAIService(apiKey)

	return &Controller{
		SourceS3:      srcS3,
		GeneratedS3:   genS3,
		AIService:     aiSvc,
		KeyGenService: services.NewKeyGenService(),
		DB:            db,
	}
}

// HandleGeneratePassword is the main flow
func (ctrl *Controller) HandleGeneratePassword(c *gin.Context) {
	// 1. Parse Request Body for optional Length and GroupID
	type GenerateRequest struct {
		Length  int        `json:"length"`
		GroupID *uuid.UUID `json:"group_id"` // Optional UUID
	}
	var req GenerateRequest
	// Ignore error if body is empty or malformed, just default to 20
	c.ShouldBindJSON(&req)

	passwordLength := req.Length
	if passwordLength < 8 {
		passwordLength = 20
	}
	if passwordLength > 32 {
		passwordLength = 32
	}

	// 2. Find latest original image
	key, err := ctrl.SourceS3.GetLatestLavaLampImage()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to find image: " + err.Error()})
		return
	}

	// 3. Download it
	imgData, err := ctrl.SourceS3.DownloadImage(key)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to download image: " + err.Error()})
		return
	}

	// 4. Generate AI Wallpaper (REQUIRED now)
	var wallpaperData []byte
	if ctrl.AIService != nil {
		wallpaperData, err = ctrl.AIService.GenerateWallpaper(imgData)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "AI Generation failed: " + err.Error()})
			return
		}
	} else {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "AI Service not initialized"})
		return
	}

	// 5. Upload AI Result to Second Bucket
	wpKey := "wallpaper_" + fmt.Sprintf("%d", time.Now().Unix()) + ".jpg"
	_, err = ctrl.GeneratedS3.UploadImage(wpKey, wallpaperData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload wallpaper: " + err.Error()})
		return
	}

	// 6. Generate Password (FROM AI DATA)
	password := ctrl.KeyGenService.GeneratePassword(wallpaperData, passwordLength)
	entropy := ctrl.KeyGenService.CalculateEntropyEstimate(password)

	// 7. DO NOT Save to DB automatically.
	// We just return the keys and data. Use HandleCreatePassword to save.

	// 8. Construct Response
	imgUrl, _ := ctrl.SourceS3.GeneratePresignedGETURL(key)
	wpUrl, _ := ctrl.GeneratedS3.GeneratePresignedGETURL(wpKey)

	c.JSON(http.StatusOK, gin.H{
		"password":         password,
		"entropy_bits":     entropy,
		"image_url":        imgUrl, // Preview URL
		"wallpaper_url":    wpUrl,  // Preview URL
		"s3_key":           key,    // To pass back on save
		"wallpaper_s3_key": wpKey,  // To pass back on save
		"created_at":       time.Now(),
	})
}

// HandleCreatePassword allows manual creation of passwords (e.g. from Vault)
func (ctrl *Controller) HandleCreatePassword(c *gin.Context) {
	var userIDPtr *uuid.UUID
	if val, exists := c.Get("user_id"); exists {
		if uid, ok := val.(uuid.UUID); ok {
			userIDPtr = &uid
		}
	}

	type CreateRequest struct {
		Password       string     `json:"password"`
		GroupID        *uuid.UUID `json:"group_id"`
		Name           string     `json:"name"`
		Username       string     `json:"username"`
		WebsiteURL     string     `json:"website_url"`
		S3Key          string     `json:"s3_key"`           // Optional
		WallpaperS3Key string     `json:"wallpaper_s3_key"` // Optional
	}

	var req CreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid body"})
		return
	}

	// We check entropy for manual passwords too
	entropy := ctrl.KeyGenService.CalculateEntropyEstimate(req.Password)

	entry := models.PasswordEntry{
		Password:       req.Password,
		EntropyScore:   entropy,
		UserID:         userIDPtr,
		GroupID:        req.GroupID,
		Name:           req.Name,
		Username:       req.Username,
		WebsiteURL:     req.WebsiteURL,
		S3Key:          req.S3Key,          // Persist if provided
		WallpaperS3Key: req.WallpaperS3Key, // Persist if provided
	}

	if err := ctrl.DB.Create(&entry).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create password"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":          entry.ID,
		"password":    entry.Password,
		"group_id":    entry.GroupID,
		"name":        entry.Name,
		"username":    entry.Username,
		"website_url": entry.WebsiteURL,
	})
}

// HandleListPasswords returns the history for the logged-in user
func (ctrl *Controller) HandleListPasswords(c *gin.Context) {
	userIDInterface, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
		return
	}
	userID := userIDInterface.(uuid.UUID)

	var entries []models.PasswordEntry
	if err := ctrl.DB.Where("user_id = ?", userID).Order("created_at desc").Find(&entries).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch passwords"})
		return
	}

	// Presign URLs
	type ResponseEntry struct {
		ID           uuid.UUID  `json:"id"`
		Password     string     `json:"password"`
		Entropy      int64      `json:"entropy_bits"`
		WallpaperURL string     `json:"wallpaper_url"`
		Date         time.Time  `json:"created_at"`
		GroupID      *uuid.UUID `json:"group_id"`
		Name         string     `json:"name"`
		Username     string     `json:"username"`
		WebsiteURL   string     `json:"website_url"`
	}

	var response []ResponseEntry
	for _, e := range entries {
		url := ""
		if e.WallpaperS3Key != "" {
			url, _ = ctrl.GeneratedS3.GeneratePresignedGETURL(e.WallpaperS3Key)
		}
		response = append(response, ResponseEntry{
			ID:           e.ID,
			Password:     e.Password,
			Entropy:      int64(e.EntropyScore),
			WallpaperURL: url,
			Date:         e.CreatedAt,
			GroupID:      e.GroupID,
			Name:         e.Name,
			Username:     e.Username,
			WebsiteURL:   e.WebsiteURL,
		})
	}

	c.JSON(http.StatusOK, response)
}

// HandleDeletePassword deletes a single password entry
func (ctrl *Controller) HandleDeletePassword(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	userIDInterface, _ := c.Get("user_id")
	userID := userIDInterface.(uuid.UUID)

	if err := ctrl.DB.Where("id = ? AND user_id = ?", id, userID).Delete(&models.PasswordEntry{}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete password"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Deleted"})
}

// StartMFAGeneratorLoop runs in the background to generate MFA seeds
func (ctrl *Controller) StartMFAGeneratorLoop() {
	ticker := time.NewTicker(30 * time.Second)
	go func() {
		for range ticker.C {
			fmt.Println("Generating new MFA seed...")

			// 1. Get latest image from Source S3
			key, err := ctrl.SourceS3.GetLatestLavaLampImage()
			if err != nil {
				fmt.Printf("MFA Loop Error: Failed to get latest image: %v\n", err)
				continue
			}

			// 2. Download Image
			imgData, err := ctrl.SourceS3.DownloadImage(key)
			if err != nil {
				fmt.Printf("MFA Loop Error: Failed to download image: %v\n", err)
				continue
			}

			// 3. Generate AI Wallpaper (optional but part of entropy flow)
			var wallpaperData []byte
			if ctrl.AIService != nil {
				wallpaperData, err = ctrl.AIService.GenerateWallpaper(imgData)
				if err != nil {
					fmt.Printf("MFA Loop Error: AI Generation failed: %v\n", err)
					// Fallback: use original image data if AI fails
					wallpaperData = imgData
				}
			} else {
				wallpaperData = imgData
			}

			// 4. Upload AI Result to Second Bucket
			wpKey := "wallpaper_" + fmt.Sprintf("%d", time.Now().Unix()) + ".jpg"
			_, err = ctrl.GeneratedS3.UploadImage(wpKey, wallpaperData)
			if err != nil {
				fmt.Printf("MFA Loop Error: Failed to upload wallpaper: %v\n", err)
				// Continue anyway, maybe use original key as fallback?
				// For now, let's just proceed with original key if upload fails for robustness,
				// or maybe we should fail? Let's proceed but log.
			} else {
				// If upload succeeded, use the AI wallpaper key
				key = wpKey
			}

			// 5. Generate Seed
			seed := ctrl.KeyGenService.GenerateMFACode(wallpaperData)

			// 6. Store in DB
			code := models.MFACode{
				Seed:      seed,
				ImageURL:  key, // Stores the AI wallpaper key (or original if upload failed)
				CreatedAt: time.Now(),
				ExpiresAt: time.Now().Add(60 * time.Second),
			}

			if err := ctrl.DB.Create(&code).Error; err != nil {
				fmt.Printf("MFA Loop Error: Failed to save to DB: %v\n", err)
				continue
			}

			fmt.Printf("MFA Seed Generated: %s\n", seed)

			// 7. Strict Cleanup: Delete ALL old codes immediately
			// The user wants old codes gone as soon as a new one appears.
			if err := ctrl.DB.Where("id != ?", code.ID).Delete(&models.MFACode{}).Error; err != nil {
				fmt.Printf("MFA Loop Error: Failed to cleanup old codes: %v\n", err)
			}
		}
	}()
}

// HandleGenerateMFACode returns the currently valid MFA seed
func (ctrl *Controller) HandleGenerateMFACode(c *gin.Context) {
	var code models.MFACode
	// Find the latest valid code
	if err := ctrl.DB.Where("expires_at > ?", time.Now()).Order("created_at desc").First(&code).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No valid MFA code found (generating...)"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"seed":        code.Seed,
		"valid_until": code.ExpiresAt,
	})
}
