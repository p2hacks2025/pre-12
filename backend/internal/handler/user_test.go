package handler

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

func TestGetMyProfileSuccess(t *testing.T) {
	// Gin をテストモードに
	gin.SetMode(gin.TestMode)

	// .env 読み込み
	if err := godotenv.Load("../../.env"); err != nil {
		t.Fatal("failed to load .env")
	}

	// DB 初期化
	db.Init()

	// ルーター作成
	r := gin.Default()
	r.GET("/me", GetMyProfile)

	// 既存ユーザーのID（実データに合わせて変更）
	userID := "c14d7427-e7ca-4987-985e-9cb6f5c9d3f8"

	// リクエスト作成（クエリパラメータ付き）
	req := httptest.NewRequest(
		http.MethodGet,
		"/me?user_id="+userID,
		nil,
	)

	// レスポンス取得
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	// ステータスコード確認
	if w.Code != http.StatusOK {
		t.Fatalf(
			"expected status 200, got %d, body=%s",
			w.Code,
			w.Body.String(),
		)
	}
}
