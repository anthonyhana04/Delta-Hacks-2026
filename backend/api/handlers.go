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
	// 1. Find latest original image
	key, err := ctrl.SourceS3.GetLatestLavaLampImage()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to find image: " + err.Error()})
		return
	}

	// 2. Download it
	imgData, err := ctrl.SourceS3.DownloadImage(key)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to download image: " + err.Error()})
		return
	}

	// 3. Generate AI Wallpaper (REQUIRED now)
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

	// 4. Upload AI Result to Second Bucket
	wpKey := "wallpaper_" + fmt.Sprintf("%d", time.Now().Unix()) + ".jpg"
	_, err = ctrl.GeneratedS3.UploadImage(wpKey, wallpaperData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload wallpaper: " + err.Error()})
		return
	}

	// 5. Generate Password (FROM AI DATA)
	password := ctrl.KeyGenService.GeneratePassword(wallpaperData, 20)
	entropy := ctrl.KeyGenService.CalculateEntropyEstimate(password)

	// 6. Save to DB
	entry := models.PasswordEntry{
		S3Key:          key,
		WallpaperS3Key: wpKey,
		Password:       password,
		EntropyScore:   entropy,
	}

	if ctrl.DB != nil {
		if err := ctrl.DB.Create(&entry).Error; err != nil {
			fmt.Printf("Failed to save to DB: %v\n", err)
		}
	}

	// 7. Construct Response with Signed URLs
	imgUrl, _ := ctrl.SourceS3.GeneratePresignedGETURL(key)
	wpUrl, _ := ctrl.GeneratedS3.GeneratePresignedGETURL(wpKey)

	c.JSON(http.StatusOK, gin.H{
		"id":            entry.ID,
		"password":      password,
		"entropy_bits":  entropy,
		"image_url":     imgUrl,
		"wallpaper_url": wpUrl,
		"created_at":    entry.CreatedAt,
	})
}
