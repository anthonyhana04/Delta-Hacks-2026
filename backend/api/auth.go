package api

import (
    "context"
    "net/http"
    "os"

    "github.com/anthonyhana04/Delta-Hacks-2026/backend/models"
    "github.com/gin-contrib/sessions"
    "github.com/gin-gonic/gin"
    "google.golang.org/api/idtoken"
)

type GoogleAuthRequest struct {
    IDToken string `json:"id_token" binding:"required"`
}

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
        // Create new user
        user = models.User{
            GoogleID: googleID,
            Email:    email,
            Name:     name,
        }
        ctrl.DB.Create(&user)
    } else {
        // Update user info
        user.Email = email
        user.Name = name
        ctrl.DB.Save(&user)
    }

    // Create Session
    session := sessions.Default(c)
    session.Set("user_id", user.ID)
    session.Save()

    c.JSON(http.StatusOK, gin.H{
        "message": "Login successful",
        "user": user,
    })
}

func (ctrl *Controller) AuthMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        session := sessions.Default(c)
        userID := session.Get("user_id")
        if userID == nil {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
            c.Abort()
            return
        }
        
        // Add UserID to context for handlers to use
        c.Set("user_id", userID)
        c.Next()
    }
}
