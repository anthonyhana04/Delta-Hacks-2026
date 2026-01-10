package database

import (
	"fmt"
	"log"
	"os"

	"github.com/anthonyhana04/Delta-Hacks-2026/backend/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func InitDB() *gorm.DB {
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=require",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"),
		os.Getenv("DB_PORT"),
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Printf("Failed to connect to database: %v", err)
		return nil
	}

	// Auto Migrate
	log.Println("Migrating database schema...")
    // Migrate User first
    if err := db.AutoMigrate(&models.User{}); err != nil {
       log.Printf("Failed to migrate User: %v", err)
    }
    // Then PasswordEntry
	if err := db.AutoMigrate(&models.PasswordEntry{}); err != nil {
		log.Printf("Failed to migrate PasswordEntry: %v", err)
	}

	return db
}
