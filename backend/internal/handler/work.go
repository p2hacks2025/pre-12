package handler

import (
	"context"
	"fmt"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
	"github.com/p2hacks2025/pre-12/backend/internal/storage"
)

func PostWork(c *gin.Context) {
	// クライアントから送られてくる情報
	userID := c.PostForm("user_id")
	title := c.PostForm("title")
	description := c.PostForm("description")

	if userID == "" || title == "" {
		c.JSON(400, gin.H{"error": "user_id and title required"})
		return
	}

	// 画像ファイル取得
	fileHeader, err := c.FormFile("image")
	if err != nil {
		c.JSON(400, gin.H{"error": "image required"})
		return
	}

	newPath := fmt.Sprintf("%s/%s", userID, fileHeader.Filename) // works バケット内のパス

	//Supabase Storage にアップロード
	if err := storage.UploadToSupabase(c, fileHeader, "works", newPath); err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	workPath := "works/" + newPath

	// ③ DB に保存（同じ user_id + image_path があれば上書き）
	_, err = db.Pool.Exec(
		context.Background(),
		`INSERT INTO works (user_id, image_path, title, description)
		 VALUES ($1, $2, $3, $4)
		 ON CONFLICT (user_id, image_path)
		 DO UPDATE SET title = EXCLUDED.title,
		               description = EXCLUDED.description`,
		userID, workPath, title, description,
	)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	c.JSON(201, gin.H{"message": "ok"})
}
