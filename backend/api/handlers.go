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

	// 7. Save to DB
	var userIDPtr *uuid.UUID
	if val, exists := c.Get("user_id"); exists {
		if uid, ok := val.(uuid.UUID); ok {
			userIDPtr = &uid
		}
	}

	entry := models.PasswordEntry{
		S3Key:          key,
		WallpaperS3Key: wpKey,
		Password:       password,
		EntropyScore:   entropy,
		UserID:         userIDPtr,
		GroupID:        req.GroupID, // Persist GroupID
	}

	if ctrl.DB != nil {
		if err := ctrl.DB.Create(&entry).Error; err != nil {
			fmt.Printf("Failed to save to DB: %v\n", err)
		}
	}

	// 8. Construct Response
	imgUrl, _ := ctrl.SourceS3.GeneratePresignedGETURL(key)
	wpUrl, _ := ctrl.GeneratedS3.GeneratePresignedGETURL(wpKey)

	c.JSON(http.StatusOK, gin.H{
		"id":            entry.ID,
		"password":      password,
		"entropy_bits":  entropy,
		"image_url":     imgUrl,
		"wallpaper_url": wpUrl,
		"created_at":    entry.CreatedAt,
		"group_id":      entry.GroupID,
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
		Password string     `json:"password"`
		GroupID  *uuid.UUID `json:"group_id"`
		// Could accept wallpaper_key if we allow reusing existing, but for now we won't.
		// Or we could trigger a mocked wallpaper for manual entries?
		// For simplicity, let's leave wallpaper empty or use a default if available.
	}

	var req CreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid body"})
		return
	}

	// We check entropy for manual passwords too
	entropy := ctrl.KeyGenService.CalculateEntropyEstimate(req.Password)

	entry := models.PasswordEntry{
		Password:     req.Password,
		EntropyScore: entropy,
		UserID:       userIDPtr,
		GroupID:      req.GroupID,
		// S3Key / Wallpaper left empty for manual entries currently
	}

	if err := ctrl.DB.Create(&entry).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create password"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":       entry.ID,
		"password": entry.Password,
		"group_id": entry.GroupID,
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
