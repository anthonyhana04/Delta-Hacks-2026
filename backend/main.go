package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
    "github.com/joho/godotenv"
	"github.com/anthonyhana04/Delta-Hacks-2026/backend/api"
)

func main() {
    // Load env vars
    err := godotenv.Load()
    if err != nil {
        log.Println("Note: .env file not found, using system environment variables")
    }

	r := gin.Default()

	ctrl := api.NewController()

	r.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "pong",
		})
	})

    r.POST("/api/generate-password", ctrl.HandleGeneratePassword)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
