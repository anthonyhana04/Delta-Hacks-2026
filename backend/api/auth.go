package api

import (
	"context"
	"net/http"
	"os"

	"github.com/anthonyhana04/Delta-Hacks-2026/backend/models"
	"github.com/gin-contrib/sessions"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"google.golang.org/api/idtoken"
)

// GoogleAuthRequest defines the payload for Google Sign-In
type GoogleAuthRequest struct {
	IDToken string `json:"id_token" binding:"required"`
}

// HandleGoogleLogin verifies the ID token from the client and creates a session
func (ctrl *Controller) HandleGoogleLogin(c *gin.Context) {
	var req GoogleAuthRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id_token required"})
		return
	}

	clientID := os.Getenv("GOOGLE_CLIENT_ID")
	if clientID == "" {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Server misconfiguration: GOOGLE_CLIENT_ID missing"})
		return
	}

	// Verify the Token with Google
	payload, err := idtoken.Validate(context.Background(), req.IDToken, clientID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid Token: " + err.Error()})
		return
	}

	// Extract User Info
	googleID := payload.Subject
	email, _ := payload.Claims["email"].(string)
	name, _ := payload.Claims["name"].(string)

	// Find or Create User
	var user models.User
	result := ctrl.DB.Where(&models.User{GoogleID: googleID}).First(&user)
	if result.Error != nil {
		// Create new user with explicit UUID
		user = models.User{
			ID:       uuid.New(),
			GoogleID: googleID,
			Email:    email,
			Name:     name,
		}
		if err := ctrl.DB.Create(&user).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
			return
		}
	} else {
		// Update user info
		user.Email = email
		user.Name = name
		ctrl.DB.Save(&user)
	}

	// Create Session
	session := sessions.Default(c)
	// Store UUID string in session to be safe with gob serialization
	session.Set("user_id", user.ID.String())
	session.Save()

	c.JSON(http.StatusOK, gin.H{
		"message": "Login successful",
		"user":    user,
	})
}

func (ctrl *Controller) AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		session := sessions.Default(c)
		userIDStr := session.Get("user_id")
		if userIDStr == nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
			c.Abort()
			return
		}

		// Parse UUID
		idStr, ok := userIDStr.(string)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid session data"})
			c.Abort()
			return
		}

		userID, err := uuid.Parse(idStr)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid User ID"})
			c.Abort()
			return
		}

		// Add UserID to context for handlers to use
		c.Set("user_id", userID)
		c.Next()
	}
}
