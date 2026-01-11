package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type MFACode struct {
	ID        uuid.UUID      `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	Seed      string         `gorm:"not null" json:"seed"`
	ImageURL  string         `json:"image_url"`
	CreatedAt time.Time      `json:"created_at"`
	ExpiresAt time.Time      `json:"expires_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}
