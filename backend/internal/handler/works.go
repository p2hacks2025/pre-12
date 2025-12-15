package handler

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

// WorkResponse は Flutter に返す作品情報の構造体
type WorkResponse struct {
	ID          string `json:"id"`
	UserID      string `json:"user_id"`
	Username    string `json:"username"`
	IconURL     string `json:"icon_url"`
	ImageURL    string `json:"image_url"`
	Title       string `json:"title"`
	Description string `json:"description"`
	CreatedAt   string `json:"created_at"`
}

// GetWorks はホーム画面用に作品一覧を返す
func GetWorks(c *gin.Context) {
	userID := c.Query("user_id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
		return
	}

	ctx := context.Background()

	// パフォーマンス改善: LEFT JOIN で未スワイプ作品を取得
	rows, err := db.Pool.Query(ctx, `
		SELECT w.id, w.user_id, u.username, u.icon_url, w.image_url, w.title, w.description, w.created_at
		FROM public.works w
		JOIN public.users u ON u.id = w.user_id
		LEFT JOIN public.swipes s ON s.from_user_id = $1 AND s.to_work_id = w.id
		LEFT JOIN public.user_progress up ON up.user_id = $1
		WHERE w.user_id <> $1
		  AND s.id IS NULL                     -- 未スワイプ
		  AND (up.last_viewed IS NULL OR w.created_at > up.last_viewed)
		ORDER BY w.created_at DESC
		LIMIT 10
	`, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	var works []WorkResponse
	var newestCreatedAt time.Time

	for rows.Next() {
		var w WorkResponse
		var createdAt time.Time
		if err := rows.Scan(&w.ID, &w.UserID, &w.Username, &w.IconURL, &w.ImageURL, &w.Title, &w.Description, &createdAt); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		w.CreatedAt = createdAt.Format(time.RFC3339)
		works = append(works, w)

		if newestCreatedAt.IsZero() || createdAt.After(newestCreatedAt) {
			newestCreatedAt = createdAt
		}
	}

	// user_progress を更新（失敗しても作品は返す）
	if !newestCreatedAt.IsZero() {
		_, err := db.Pool.Exec(ctx, `
			INSERT INTO public.user_progress (user_id, last_viewed)
			VALUES ($1, $2)
			ON CONFLICT (user_id) DO UPDATE
			SET last_viewed = EXCLUDED.last_viewed
		`, userID, newestCreatedAt)
		if err != nil {
			fmt.Println("failed to update user_progress:", err)
		}
	}

	c.JSON(http.StatusOK, works)
}
