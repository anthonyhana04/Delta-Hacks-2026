package api

import (
	"net/http"

	"github.com/anthonyhana04/Delta-Hacks-2026/backend/models"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// HandleListGroups returns the user's groups
func (ctrl *Controller) HandleListGroups(c *gin.Context) {
	userIDInterface, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
		return
	}
	userID := userIDInterface.(uuid.UUID)

	var groups []models.VaultGroup
	if err := ctrl.DB.Where("user_id = ?", userID).Find(&groups).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch groups"})
		return
	}

	// Helper to ensure default groups exist if none are found
	// NOTE: In a real app, successful login usually creates these.
	// For this hackathon, lazily creating them on fetch is robustness.
	if len(groups) == 0 {
		defaultGroups := []models.VaultGroup{
			{UserID: userID, Name: "Social", Icon: "message.fill", Color: "#A020F0"},  // Purple
			{UserID: userID, Name: "Work", Icon: "briefcase.fill", Color: "#FFA500"},  // Orange
			{UserID: userID, Name: "Family", Icon: "house.fill", Color: "#008000"},    // Green
			{UserID: userID, Name: "Personal", Icon: "person.fill", Color: "#0000FF"}, // Blue
		}

		if err := ctrl.DB.Create(&defaultGroups).Error; err == nil {
			groups = defaultGroups
		}
	}

	c.JSON(http.StatusOK, groups)
}

// HandleCreateGroup creates a new group
func (ctrl *Controller) HandleCreateGroup(c *gin.Context) {
	userIDInterface, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found"})
		return
	}
	userID := userIDInterface.(uuid.UUID)

	type CreateGroupRequest struct {
		Name  string `json:"name"`
		Icon  string `json:"icon"`
		Color string `json:"color"`
	}
	var req CreateGroupRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	newGroup := models.VaultGroup{
		UserID: userID,
		Name:   req.Name,
		Icon:   req.Icon,
		Color:  req.Color,
	}

	if err := ctrl.DB.Create(&newGroup).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create group"})
		return
	}

	c.JSON(http.StatusOK, newGroup)
}

// HandleDeleteGroup deletes a group
func (ctrl *Controller) HandleDeleteGroup(c *gin.Context) {
	// Note: For now, we won't cascade delete passwords, they will just become "All" (group_id: null)
	// Or we could block delete if not empty.
	// User requested "no passwords in group by default".

	idStr := c.Param("id")

	// Validate UUID format
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid Group ID format"})
		return
	}

	// We should verify ownership
	userIDInterface, _ := c.Get("user_id")
	userID := userIDInterface.(uuid.UUID)

	if err := ctrl.DB.Where("id = ? AND user_id = ?", id, userID).Delete(&models.VaultGroup{}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete group"})
		return
	}

	// Unlink passwords in this group
	ctrl.DB.Model(&models.PasswordEntry{}).Where("group_id = ?", id).Update("group_id", nil)

	c.JSON(http.StatusOK, gin.H{"message": "Group deleted"})
}
