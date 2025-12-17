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

func PostSwipe(c *gin.Context) {
	var req SwipeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	ctx := context.Background()

	// スワイプ保存
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

	if res.RowsAffected() == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "cannot swipe your own work or invalid work_id"})
		return
	}

	// マッチ判定（いいねの場合のみ）
	if req.IsLike {
		var toWorkUserID string
		// 作品の作者ID取得
		err := db.Pool.QueryRow(ctx, `SELECT user_id FROM works WHERE id=$1`, req.ToWorkID).Scan(&toWorkUserID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		// 相手が自分の作品にいいねしているか確認
		var otherWorkID string
		err = db.Pool.QueryRow(ctx, `
			SELECT to_work_id 
			FROM public.swipes 
			WHERE from_user_id=$1 AND to_work_user_id=$2 AND is_like=true
		`, toWorkUserID, req.FromUserID).Scan(&otherWorkID)

		if err == nil {
			// マッチ成立
			user1ID := req.FromUserID
			user2ID := toWorkUserID
			work1ID := req.ToWorkID
			work2ID := otherWorkID

			// UUID 小さい順で固定
			if user2ID < user1ID {
				user1ID, user2ID = user2ID, user1ID
				work1ID, work2ID = work2ID, work1ID
			}

			_, err = db.Pool.Exec(ctx, `
				INSERT INTO public.matches (user1_id, user2_id, work1_id, work2_id)
				VALUES ($1, $2, $3, $4)
				ON CONFLICT (user1_id, user2_id) DO NOTHING
			`, user1ID, user2ID, work1ID, work2ID)

			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": "swipe saved"})
}
