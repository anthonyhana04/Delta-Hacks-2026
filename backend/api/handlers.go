package api

import (
	"net/http"
	"os"

	"github.com/anthonyhana04/Delta-Hacks-2026/backend/services"
	"github.com/gin-gonic/gin"
)

type Controller struct {
	S3Service     *services.S3Service
	AIService     *services.AIService
	KeyGenService *services.KeyGenService
}

func NewController() *Controller {
	// Initialize services
	bucket := os.Getenv("AWS_BUCKET_NAME")
	if bucket == "" {
		bucket = "your-lava-lamp-bucket" // Fallback
	}
	region := os.Getenv("AWS_REGION")
	if region == "" {
		region = "us-east-1"
	}

	s3Svc, err := services.NewS3Service(region, bucket)
	if err != nil {
		// Log error but don't crash, middleware might handle it or just fail requests
	}

	return &Controller{
		S3Service:     s3Svc,
		AIService:     services.NewAIService(),
		KeyGenService: services.NewKeyGenService(),
	}
}

// HandleGeneratePassword is the main flow
func (ctrl *Controller) HandleGeneratePassword(c *gin.Context) {
	// 1. Find latest image
	key, err := ctrl.S3Service.GetLatestLavaLampImage()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to find image: " + err.Error()})
		return
	}

	// 2. Download it
	imgData, err := ctrl.S3Service.DownloadImage(key)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to download image: " + err.Error()})
		return
	}

	// 3. Generate Password
	password := ctrl.KeyGenService.GeneratePassword(imgData, 20) // 20 chars
	entropy := ctrl.KeyGenService.CalculateEntropyEstimate(password)

	// 4. (Optional) Extend Image via AI
	// wallpaperData, _ := ctrl.AIService.ExtendImage(imgData)
	// For now, we return the original image URL as the thumbnail.
	// In a full version, we'd upload the wallpaper and return that URL too.

	// Construct public URL for the image (assuming public-read or presigned)
	// Simple S3 URL construction:
	imgUrl := "https://" + ctrl.S3Service.Bucket + ".s3.amazonaws.com/" + key

	c.JSON(http.StatusOK, gin.H{
		"password":     password,
		"entropy_bits": entropy,
		"original_img": imgUrl,
		"wallpaper_img": imgUrl, // Placeholder: same as original
		"source_key":   key,
	})
}
