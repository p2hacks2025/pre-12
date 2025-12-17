package handler

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
	"github.com/p2hacks2025/pre-12/backend/internal/lib"
)

type UserProfileResponse struct {
	ID       string  `json:"id"`
	Username string  `json:"username"`
	Email    string  `json:"email"`
	IconURL  *string `json:"icon_url"`
	Bio      *string `json:"bio"`
}

func GetMyProfile(c *gin.Context) {
	userID := c.Query("user_id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
		return
	}

	var profile UserProfileResponse
	var iconPath *string

	err := db.Pool.QueryRow(
		context.Background(),
		`SELECT id, username, email, icon_path, bio
		 FROM public.users
		 WHERE id = $1`,
		userID,
	).Scan(
		&profile.ID,
		&profile.Username,
		&profile.Email,
		&iconPath,
		&profile.Bio,
	)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}

	if iconPath != nil {
		url := lib.BuildPublicURL(*iconPath)
		profile.IconURL = &url
	}

	c.JSON(http.StatusOK, profile)
}
