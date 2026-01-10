package models

import (
	"time"

	"gorm.io/gorm"
)

type PasswordEntry struct {
	ID           uint           `gorm:"primaryKey" json:"id"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
	
	S3Key           string `json:"s3_key"`
    WallpaperS3Key  string `json:"wallpaper_s3_key"` // New field for the AI generated image
	Password        string `json:"password"` 
	EntropyScore    int    `json:"entropy_score"`
}
