package handler

import (
	"context"
	"fmt"
	"path/filepath"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
	"github.com/p2hacks2025/pre-12/backend/internal/storage"
)

func PostWork(c *gin.Context) {
	userID := c.PostForm("user_id")
	title := c.PostForm("title")
	description := c.PostForm("description")

	if userID == "" || title == "" {
		c.JSON(400, gin.H{"error": "user_id and title required"})
		return
	}

	fileHeader, err := c.FormFile("image")
	if err != nil {
		c.JSON(400, gin.H{"error": "image required"})
		return
	}

	// ① path を決める
	imagePath := fmt.Sprintf(
		"works/%s/%s",
		userID,
		uuid.New().String()+filepath.Ext(fileHeader.Filename),
	)

	// ② Supabase Storage に upload
	if err := storage.UploadToSupabase(c, fileHeader, imagePath); err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	// ③ DB に path を保存
	_, err = db.Pool.Exec(
		context.Background(),
		`INSERT INTO works (user_id, image_path, title, description)
		 VALUES ($1, $2, $3, $4)`,
		userID, imagePath, title, description,
	)

	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	c.JSON(201, gin.H{"message": "ok"})
}
