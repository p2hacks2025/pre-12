package handler

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
	"github.com/p2hacks2025/pre-12/backend/internal/service"
)

// SwipeRequest は Flutter から送られてくるスワイプ情報
type SwipeRequest struct {
	FromUserID string `json:"from_user_id"`
	ToWorkID   string `json:"to_work_id"`
	IsLike     bool   `json:"is_like"`
}

func PostSwipe(c *gin.Context) {
	var req SwipeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	ctx := context.Background()

	// ① スワイプ保存（同期）
	res, err := db.Pool.Exec(ctx, `
		INSERT INTO public.swipes (from_user_id, to_work_id, to_work_user_id, is_like)
		SELECT $1, w.id, w.user_id, $2
		FROM public.works w
		WHERE w.id = $3 AND w.user_id <> $1
		ON CONFLICT (from_user_id, to_work_id) DO UPDATE
		SET is_like = EXCLUDED.is_like, created_at = now()
	`, req.FromUserID, req.IsLike, req.ToWorkID)

	if err != nil || res.RowsAffected() == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "swipe failed"})
		return
	}

	// ② 即レスポンス（UX最優先）
	c.JSON(http.StatusOK, gin.H{"message": "swipe saved"})

	// ③ マッチ判定は非同期
	if req.IsLike {
		go service.CheckAndCreateMatch(req.FromUserID, req.ToWorkID)
	}
}
