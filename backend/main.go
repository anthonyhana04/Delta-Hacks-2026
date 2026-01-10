package main

import (
	"log"
	"net/http"
	"os"

	"github.com/anthonyhana04/Delta-Hacks-2026/backend/api"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
    // Load env vars
    if err := godotenv.Load(); err != nil {
        log.Println("Note: .env file not found, using system environment variables")
    } else {
        log.Println("Loaded .env file successfully")
    }
    
    // Debug: Print DB config (masking password)
    log.Printf("DB Config: Host=%s User=%s DB=%s Port=%s", 
        os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_NAME"), os.Getenv("DB_PORT"))


	r := gin.Default()
    ctrl := api.NewController()

	r.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "pong",
		})
	})

    // Main interaction endpoint
    r.POST("/api/generate-password", ctrl.HandleGeneratePassword)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Lava Banana Backend starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
