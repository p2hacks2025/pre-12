package handler

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

type CreateWorkRequest struct {
	UserID      string `json:"user_id"`
	ImageURL    string `json:"image_url"`
	Title       string `json:"title"`
	Description string `json:"description"`
}

func PostWork(c *gin.Context) {
	var req CreateWorkRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	if req.UserID == "" || req.ImageURL == "" || req.Title == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "user_id, image_url, title are required",
		})
		return
	}

	ctx := context.Background()

	_, err := db.Pool.Exec(ctx, `
		INSERT INTO public.works (user_id, image_url, title, description)
		VALUES ($1, $2, $3, $4)
	`, req.UserID, req.ImageURL, req.Title, req.Description)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "ok"})
}
