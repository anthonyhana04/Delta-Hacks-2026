package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type PasswordEntry struct {
	ID        uuid.UUID      `gorm:"type:uuid;primaryKey" json:"id"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`

	UserID         *uuid.UUID `json:"user_id"`
	GroupID        *uuid.UUID `json:"group_id"`
	S3Key          string     `json:"s3_key"`
	WallpaperS3Key string     `json:"wallpaper_s3_key"`
	Password       string     `json:"password"`
	EntropyScore   int        `json:"entropy_score"`

	// Metadata
	Name       string `json:"name"`
	Username   string `json:"username"`
	WebsiteURL string `json:"website_url"`
}

func (base *PasswordEntry) BeforeCreate(tx *gorm.DB) (err error) {
	if base.ID == uuid.Nil {
		base.ID = uuid.New()
	}
	return
}
