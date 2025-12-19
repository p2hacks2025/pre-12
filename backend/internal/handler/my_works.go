package handler

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
	"github.com/p2hacks2025/pre-12/backend/internal/lib"
)

type MyWorkResponse struct {
	ID          string `json:"id"`
	ImageURL    string `json:"image_url"`
	Title       string `json:"title"`
	Description string `json:"description"`
	CreatedAt   string `json:"created_at"`
}

// GetMyWorks - 指定ユーザーの作品一覧を返す
func GetMyWorks(c *gin.Context) {
	userID := c.Query("user_id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
		return
	}

	ctx := context.Background()

	rows, err := db.Pool.Query(
		ctx,
		`SELECT id, image_path, title, description, created_at
		 FROM public.works
		 WHERE user_id = $1
		 ORDER BY created_at DESC`,
		userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to query works"})
		return
	}
	defer rows.Close()

	var works []MyWorkResponse

	for rows.Next() {
		var w MyWorkResponse
		var imagePath, description *string
		var createdAt time.Time
		if err := rows.Scan(&w.ID, &imagePath, &w.Title, &description, &createdAt); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to scan work"})
			return
		}

		// 画像URL
		const DefaultImagePath = "images/default.png"

		if imagePath != nil {
			w.ImageURL = lib.BuildPublicURL(*imagePath)
		} else {
			w.ImageURL = lib.BuildPublicURL(DefaultImagePath)
		}

		// description が nil の場合は空文字にする
		if description != nil {
			w.Description = *description
		} else {
			w.Description = ""
		}

		w.CreatedAt = createdAt.Format(time.RFC3339)

		works = append(works, w)
	}

	c.JSON(http.StatusOK, works)
}
