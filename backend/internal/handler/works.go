package handler

import (
	"context"
	"math/rand"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
	"github.com/p2hacks2025/pre-12/backend/internal/lib"
)

// WorkResponse は Flutter に返す作品情報の構造体
type WorkResponse struct {
	ID          string `json:"work_id"`
	UserID      string `json:"user_id"`
	Username    string `json:"username"`
	IconURL     string `json:"icon_url"`
	ImageURL    string `json:"image_url"`
	Title       string `json:"title"`
	Description string `json:"description"`
	CreatedAt   string `json:"created_at"`
}

// GetWorks はホーム画面用に未スワイプ作品をランダムに返す（高速版）
func GetWorks(c *gin.Context) {
	userID := c.Query("user_id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
		return
	}

	ctx := context.Background()

	// 1. 未スワイプ作品IDを取得
	idRows, err := db.Pool.Query(ctx, `
		SELECT w.id
		FROM public.works w
		LEFT JOIN public.swipes s ON s.from_user_id = $1 AND s.to_work_id = w.id
		WHERE w.user_id <> $1
		  AND s.id IS NULL
	`, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer idRows.Close()

	var workIDs []string
	for idRows.Next() {
		var id string
		if err := idRows.Scan(&id); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		workIDs = append(workIDs, id)
	}

	if len(workIDs) == 0 {
		// 未スワイプ作品がない場合
		c.JSON(http.StatusOK, []WorkResponse{})
		return
	}

	// 2. Goでランダムに10件選択
	rand.Seed(time.Now().UnixNano())
	rand.Shuffle(len(workIDs), func(i, j int) { workIDs[i], workIDs[j] = workIDs[j], workIDs[i] })

	selectedIDs := workIDs
	if len(workIDs) > 10 {
		selectedIDs = workIDs[:10]
	}

	// 3. 選ばれたIDで作品情報をまとめて取得
	query := `
		SELECT w.id, w.user_id, u.username, u.icon_path, w.image_path, w.title, w.description, w.created_at
		FROM public.works w
		JOIN public.users u ON u.id = w.user_id
		WHERE w.id = ANY($1)
	`
	rows, err := db.Pool.Query(ctx, query, selectedIDs)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	var works []WorkResponse
	for rows.Next() {
		var w WorkResponse
		var iconPath, imagePath string
		var createdAt time.Time
		if err := rows.Scan(&w.ID, &w.UserID, &w.Username, &iconPath, &imagePath, &w.Title, &w.Description, &createdAt); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		// パスをURLに変換
		w.IconURL = lib.BuildPublicURL(iconPath)
		w.ImageURL = lib.BuildPublicURL(imagePath)
		w.CreatedAt = createdAt.Format(time.RFC3339)

		works = append(works, w)
	}

	c.JSON(http.StatusOK, works)
}
