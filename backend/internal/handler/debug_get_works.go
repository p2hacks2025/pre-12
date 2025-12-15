package handler

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

type DebugWork struct {
	ID          string `json:"id"`
	UserID      string `json:"user_id"`
	Username    string `json:"username"`
	ImageURL    string `json:"image_url"`
	Title       string `json:"title"`
	Description string `json:"description"`
}

func DebugGetWorks(c *gin.Context) {
	rows, err := db.Pool.Query(context.Background(), `
		SELECT
			w.id,
			w.user_id,
			u.username,
			w.image_url,
			w.title,
			w.description
		FROM public.works w
		JOIN public.users u ON u.id = w.user_id
		ORDER BY w.created_at DESC
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	works := []DebugWork{}

	for rows.Next() {
		var w DebugWork
		if err := rows.Scan(
			&w.ID,
			&w.UserID,
			&w.Username,
			&w.ImageURL,
			&w.Title,
			&w.Description,
		); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		works = append(works, w)
	}

	c.JSON(http.StatusOK, works)
}
