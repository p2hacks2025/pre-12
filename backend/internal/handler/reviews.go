package handler

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
	"github.com/p2hacks2025/pre-12/backend/internal/lib"
)

type ReceivedReviewResponse struct {
	ReviewID     string `json:"review_id"`
	MatchID      string `json:"match_id"`
	UserID       string `json:"user_id"`
	Username     string `json:"username"`
	IconURL      string `json:"icon_url"`
	WorkID       string `json:"work_id"`
	WorkImageURL string `json:"work_image_url"`
	Comment      string `json:"comment"`
	CreatedAt    string `json:"created_at"`
}

func GetReceivedReviews(c *gin.Context) {
	userID := c.Query("user_id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
		return
	}

	ctx := context.Background()

	rows, err := db.Pool.Query(ctx, `
		SELECT
		  r.id AS review_id,
		  r.match_id,
		  u.id AS user_id,
		  u.username,
		  u.icon_path,
		  w.id AS work_id,
		  w.image_path AS work_image_path,
		  r.comment,
		  r.created_at
		FROM public.reviews r
		JOIN public.users u
		  ON u.id = r.from_user_id
		JOIN public.works w
		  ON w.id = r.work_id
		WHERE r.to_user_id = $1
		ORDER BY r.created_at DESC
	`, userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	reviews := []ReceivedReviewResponse{}

	for rows.Next() {
		var r ReceivedReviewResponse
		var iconPath, workPath string
		if err := rows.Scan(
			&r.ReviewID,
			&r.MatchID,
			&r.UserID,
			&r.Username,
			&iconPath,
			&r.WorkID,
			&workPath,
			&r.Comment,
			&r.CreatedAt,
		); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		// path → URL
		r.IconURL = lib.BuildPublicURL(iconPath)
		r.WorkImageURL = lib.BuildPublicURL(workPath)
		reviews = append(reviews, r)
	}

	c.JSON(http.StatusOK, reviews)
}
