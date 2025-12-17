package handler

import (
	"context"
	"fmt"
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
	// Flutter などのクライアント側から ?user_id=xxxx で送信される想定
	userID := c.Query("user_id")
	if userID == "" {
		// user_id が空の場合は 400 Bad Request を返して処理終了
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
		return
	}

	// multipart/form-data 形式のリクエストから文字列フィールド "bio" を取得
	// 送信されていない場合は空文字 ""
	bio := c.PostForm("bio")

	// multipart/form-data からファイルフィールド "icon" を取得
	file, err := c.FormFile("icon")
	var iconPath *string // 後で DB に保存する画像のパスを保持
	if err == nil {      // ファイルが送られてきた場合のみ処理
		// Storage 内の保存パスを生成
		newPath := fmt.Sprintf("works/%s/%s", userID, file.Filename)

		// Supabase Storage にアップロード
		// storage.UploadToSupabase は別関数で実装済み
		err = storage.UploadToSupabase(c.Request.Context(), file, newPath)
		if err != nil {
			// アップロードに失敗したら 500 Internal Server Error を返す
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to upload icon"})
			return
		}
		// 成功したら iconPath に保存パスをセット
		iconPath = &newPath
	}

	// SQL 文の動的構築
	// 更新対象のカラムだけセットするため、params スライスと paramIdx を使う
	query := `UPDATE public.users SET `
	params := []interface{}{}
	paramIdx := 1

	// icon_path を更新する場合
	if iconPath != nil {
		query += `icon_path = $` + strconv.Itoa(paramIdx) // $1, $2 ... のパラメータ形式
		params = append(params, *iconPath)                // 実際の値をパラメータに追加
		paramIdx++
	}

	// bio を更新する場合
	if bio != "" {
		if len(params) > 0 {
			query += `, ` // すでに更新対象がある場合はカンマで区切る
		}
		query += `bio = $` + strconv.Itoa(paramIdx)
		params = append(params, bio)
		paramIdx++
	}

	// 更新対象が1つもない場合は 400 エラーを返す
	if len(params) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "nothing to update"})
		return
	}

	// WHERE 句で対象ユーザーを指定
	query += ` WHERE id = $` + strconv.Itoa(paramIdx)
	params = append(params, userID)

	// DB 更新実行
	_, err = db.Pool.Exec(context.Background(), query, params...)
	if err != nil {
		// 更新に失敗した場合は 500 エラー
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update profile"})
		return
	}

	// 正常終了レスポンス
	c.JSON(http.StatusOK, gin.H{"message": "profile updated"})
}
