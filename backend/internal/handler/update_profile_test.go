// backend/internal/handler/profile_test.go
package handler

import (
	"bytes"
	"context"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/p2hacks2025/pre-12/backend/internal/storage"
)

func TestUpdateMyProfile_Success(t *testing.T) {
	// --- ルーター登録 ---
	r := setupTestRouter(withUpdateProfile)

	// --- テスト用ユーザー作成 ---
	userID := createTestUser(t)

	// --- multipart/form-data 生成 ---
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	// icon ファイル
	part, _ := writer.CreateFormFile("icon", "icon.png")
	part.Write([]byte("dummy icon content"))

	// bio フィールド
	writer.WriteField("bio", "This is my new bio")
	writer.Close()

	// リクエスト作成
	req := httptest.NewRequest(http.MethodPost, "/update-profile?user_id="+userID, body)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}

	// --- Storage cleanup ---
	uploadedPath := userID + "/icon.png"
	if err := storage.DeleteFromSupabase(context.Background(), "icons", uploadedPath); err != nil {
		t.Fatalf("failed to cleanup storage: %v", err)
	}
}
