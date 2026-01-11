package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type VaultGroup struct {
	ID        uuid.UUID      `gorm:"type:uuid;primaryKey" json:"id"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`

	UserID uuid.UUID `json:"user_id"`
	Name   string    `json:"name"`
	Icon   string    `json:"icon"`
	Color  string    `json:"color"` // Hex string
}

func (base *VaultGroup) BeforeCreate(tx *gorm.DB) (err error) {
	if base.ID == uuid.Nil {
		base.ID = uuid.New()
	}
	return
}
