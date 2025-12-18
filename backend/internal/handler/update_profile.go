package handler

import (
	"context"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
	"github.com/p2hacks2025/pre-12/backend/internal/storage"
)

// UpdateMyProfile はユーザーのアイコン画像と自己紹介文を更新する
// multipart/form-data 形式で送信される想定
func UpdateMyProfile(c *gin.Context) {
	// クエリパラメータから user_id を取得
	userID := c.Query("user_id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
		return
	}

	// multipart/form-data 形式のリクエストから文字列フィールド "bio" を取得
	bio := c.PostForm("bio")

	// multipart/form-data からファイルフィールド "icon" を取得
	fileHeader, err := c.FormFile("icon")
	var iconPath *string
	if err == nil {
		// 保存パスをバケット名を含めて生成
		newPath := "icons/" + userID + "/" + fileHeader.Filename

		// Supabase Storage にアップロード（同じパスなら上書き）
		if err := storage.UploadToSupabase(c, fileHeader, "icons", userID+"/"+fileHeader.Filename); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to upload icon"})
			return
		}

		iconPath = &newPath
	}

	// SQL 文の動的構築
	query := `UPDATE public.users SET `
	params := []interface{}{}
	paramIdx := 1

	if iconPath != nil {
		query += `icon_path = $` + strconv.Itoa(paramIdx)
		params = append(params, *iconPath)
		paramIdx++
	}

	if bio != "" {
		if len(params) > 0 {
			query += `, `
		}
		query += `bio = $` + strconv.Itoa(paramIdx)
		params = append(params, bio)
		paramIdx++
	}

	if len(params) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "nothing to update"})
		return
	}

	query += ` WHERE id = $` + strconv.Itoa(paramIdx)
	params = append(params, userID)

	// DB 更新（上書き）
	_, err = db.Pool.Exec(context.Background(), query, params...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update profile"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "profile updated",
	})
}
