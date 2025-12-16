package handler

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

type SignupRequest struct {
	Username string `json:"username"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

func Signup(c *gin.Context) {
	var req SignupRequest
	if err := c.BindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	// すでに同じメールアドレスがあるかチェック
	var exists bool
	err := db.Pool.QueryRow(context.Background(),
		"SELECT EXISTS(SELECT 1 FROM public.users WHERE email=$1)",
		req.Email).Scan(&exists)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}
	if exists {
		c.JSON(http.StatusConflict, gin.H{"error": "email already registered"})
		return
	}

	// 新しいユーザーを登録
	var id string
	err = db.Pool.QueryRow(context.Background(),
		"INSERT INTO public.users (username, email, password) VALUES ($1, $2, $3) RETURNING id",
		req.Username, req.Email, req.Password).Scan(&id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create user"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"id": id, "email": req.Email})
}
