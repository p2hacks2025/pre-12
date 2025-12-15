package handler

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

// SwipeRequest は Flutter から送られてくるスワイプ情報
type SwipeRequest struct {
	FromUserID string `json:"from_user_id"`
	ToWorkID   string `json:"to_work_id"`
	IsLike     bool   `json:"is_like"`
}

// PostSwipe は作品に対するスワイプをデータベースに保存する
func PostSwipe(c *gin.Context) {
	var req SwipeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	ctx := context.Background()

	// to_work_id から作品の作成者を取得して自動で to_work_user_id を設定
	// 自分の作品にはスワイプできない
	res, err := db.Pool.Exec(ctx, `
		INSERT INTO public.swipes (from_user_id, to_work_id, to_work_user_id, is_like)
		SELECT $1, w.id, w.user_id, $2
		FROM public.works w
		WHERE w.id = $3 AND w.user_id <> $1
		ON CONFLICT (from_user_id, to_work_id) DO UPDATE
		SET is_like = EXCLUDED.is_like, created_at = now()
	`, req.FromUserID, req.IsLike, req.ToWorkID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// もし行が影響されなかった場合（自分の作品をスワイプしようとした）
	if res.RowsAffected() == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "cannot swipe your own work or invalid work_id"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "swipe saved"})
}
