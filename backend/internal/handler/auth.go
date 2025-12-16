//backend/internal/handler/auth.go

package handler

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
	"github.com/p2hacks2025/pre-12/backend/internal/lib"
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

	var id, password, iconURL string
	var iconPath string
	err := db.Pool.QueryRow(context.Background(),
		"SELECT id, password, icon_path FROM public.users WHERE email=$1",
		req.Email).Scan(&id, &password, &iconPath)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user not found"})
		return
	}

	if password != req.Password {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "wrong password"})
		return
	}

	iconURL = lib.BuildPublicURL(iconPath)

	c.JSON(http.StatusOK, gin.H{"id": id, "email": req.Email, "icon_url": iconURL})
}
