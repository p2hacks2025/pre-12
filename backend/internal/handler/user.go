package handler

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
	"github.com/p2hacks2025/pre-12/backend/internal/lib"
)

type UserProfileResponse struct {
	ID       string `json:"id"`
	Username string `json:"username"`
	Email    string `json:"email"`
	IconURL  string `json:"icon_url"`
	Bio      string `json:"bio"`
}

const (
	DefaultBio      = "よろしくお願いします"
	DefaultIconPath = "icons/default.png"
)

func GetMyProfile(c *gin.Context) {
	userID := c.Query("user_id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
		return
	}

	ctx := context.Background()

	var (
		profile  UserProfileResponse
		iconPath *string
		bio      *string
	)

	err := db.Pool.QueryRow(
		ctx,
		`SELECT id, username, email, icon_path, bio
		 FROM public.users
		 WHERE id = $1`,
		userID,
	).Scan(
		&profile.ID,
		&profile.Username,
		&profile.Email,
		&iconPath,
		&bio,
	)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}

	// icon_url（必ず返す）
	if iconPath != nil {
		profile.IconURL = lib.BuildPublicURL(*iconPath)
	} else {
		profile.IconURL = lib.BuildPublicURL(DefaultIconPath)
	}

	// bio（必ず返す）
	if bio != nil {
		profile.Bio = *bio
	} else {
		profile.Bio = DefaultBio
	}

	c.JSON(http.StatusOK, profile)
}
