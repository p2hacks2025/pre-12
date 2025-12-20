package handler

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
	"github.com/p2hacks2025/pre-12/backend/internal/lib"
)

type MatchResponse struct {
	MatchID      string `json:"match_id"`
	UserID       string `json:"user_id"`
	Username     string `json:"username"`
	IconURL      string `json:"icon_url"`
	WorkImageURL string `json:"work_image_url"`
	WorkTitle    string `json:"work_title"`
}

func GetMatches(c *gin.Context) {
	userID := c.Query("user_id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
		return
	}

	ctx := context.Background()

	rows, err := db.Pool.Query(ctx, `
		SELECT
		  m.id AS match_id,
		  u.id AS user_id,
		  u.username,
		  u.icon_path,
		  w.image_path AS work_image_path,
		  w.title AS work_title
		FROM public.matches m
		JOIN public.users u
		  ON u.id = CASE
		    WHEN m.user1_id = $1 THEN m.user2_id
		    ELSE m.user1_id
		  END
		JOIN public.works w
		  ON w.id = CASE
		    WHEN m.user1_id = $1 THEN m.work2_id
		    ELSE m.work1_id
		  END
		WHERE $1 IN (m.user1_id, m.user2_id)
		ORDER BY m.created_at DESC
	`, userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	matches := []MatchResponse{}

	for rows.Next() {
		var m MatchResponse
		var iconPath, workPath *string
		if err := rows.Scan(
			&m.MatchID,
			&m.UserID,
			&m.Username,
			&iconPath,
			&workPath,
			&m.WorkTitle,
		); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		const DefaultIconPath = "icons/default.png"
		const DefaultWorkImagePath = "images/default.png"

		if iconPath != nil {
			m.IconURL = lib.BuildPublicURL(*iconPath)
		} else {
			m.IconURL = lib.BuildPublicURL(DefaultIconPath)
		}

		if workPath != nil {
			m.WorkImageURL = lib.BuildPublicURL(*workPath)
		} else {
			m.WorkImageURL = lib.BuildPublicURL(DefaultWorkImagePath)
		}

		matches = append(matches, m)
	}

	c.JSON(http.StatusOK, matches)
}
