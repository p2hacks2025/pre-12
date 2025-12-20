//backend/internal/handler/auth.go

package handler

import (
	"context"
	"net/http"

	"strings"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func Login(c *gin.Context) {
	var req LoginRequest
	if err := c.BindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	var id, password string
	err := db.Pool.QueryRow(context.Background(),
		"SELECT id, password FROM public.users WHERE LOWER(email)=$1",
		strings.ToLower(req.Email)).Scan(&id, &password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user not found"})
		return
	}

	if password != req.Password {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "wrong password"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"user_id": id})
}
