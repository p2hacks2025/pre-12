package handler

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

type UserInfo struct {
	ID    string `json:"user_id"`
	Email string `json:"email"`
}

// DebugGetUsers 全ユーザーのIDとEmailを返すデバッグ用
func DebugGetUsers(c *gin.Context) {
	rows, err := db.Pool.Query(context.Background(),
		"SELECT id, email FROM public.users")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to query users"})
		return
	}
	defer rows.Close()

	users := []UserInfo{}
	for rows.Next() {
		var u UserInfo
		if err := rows.Scan(&u.ID, &u.Email); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to scan user"})
			return
		}
		users = append(users, u)
	}

	c.JSON(http.StatusOK, gin.H{"users": users})
}
