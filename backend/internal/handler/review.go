package handler

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

type CreateReviewRequest struct {
	MatchID    string `json:"match_id"`
	FromUserID string `json:"from_user_id"`
	Comment    string `json:"comment"`
}

func PostReview(c *gin.Context) {
	var req CreateReviewRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	ctx := context.Background()

	var (
		user1ID string
		user2ID string
		work1ID string
		work2ID string
	)

	//match 情報を取得
	err := db.Pool.QueryRow(ctx, `
		SELECT user1_id, user2_id, work1_id, work2_id
		FROM public.matches
		WHERE id = $1
	`, req.MatchID).Scan(&user1ID, &user2ID, &work1ID, &work2ID)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid match_id"})
		return
	}

	//from_user / to_user / work を決定
	var toUserID string
	var workID string

	switch req.FromUserID {
	case user1ID:
		toUserID = user2ID
		workID = work2ID
	case user2ID:
		toUserID = user1ID
		workID = work1ID
	default:
		c.JSON(http.StatusForbidden, gin.H{"error": "user not in this match"})
		return
	}

	//review を保存
	_, err = db.Pool.Exec(ctx, `
		INSERT INTO public.reviews (
			match_id,
			from_user_id,
			to_user_id,
			work_id,
			comment
		)
		VALUES ($1, $2, $3, $4, $5)
	`, req.MatchID, req.FromUserID, toUserID, workID, req.Comment)

	if err != nil {
		c.JSON(http.StatusConflict, gin.H{
			"error": "already reviewed or failed to create review",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "review created",
	})
}
