package handler

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

func TestLoginSuccess(t *testing.T) {
	// Gin をテストモードに
	gin.SetMode(gin.TestMode)

	if err := godotenv.Load(); err != nil {
		t.Fatal("failed to load .env")
	}

	// DB 初期化（本番と同じ）
	db.Init()

	// ルーター作成
	r := gin.Default()
	r.POST("/login", Login)

	// リクエストボディ
	body := map[string]string{
		"email":    "user_001@example.com",
		"password": "ChangeMe-CommonPassword-2025!",
	}
	jsonBody, _ := json.Marshal(body)

	// HTTP リクエスト作成
	req := httptest.NewRequest(
		http.MethodPost,
		"/login",
		bytes.NewBuffer(jsonBody),
	)
	req.Header.Set("Content-Type", "application/json")

	// レスポンス取得
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	// ステータスコード確認
	if w.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d, body=%s", w.Code, w.Body.String())
	}
}
