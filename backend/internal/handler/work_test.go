// backend/internal/handler/work_test.go
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

func TestPostWork_Success(t *testing.T) {
	r := setupTestRouter(withPostWork)

	userID := createTestUser(t)

	// テスト用画像ファイル（バイト列で簡易的に作成）
	fileBuffer := &bytes.Buffer{}
	writer := multipart.NewWriter(fileBuffer)
	part, _ := writer.CreateFormFile("image", "test.png")
	part.Write([]byte("dummy image content"))
	writer.WriteField("user_id", userID)
	writer.WriteField("title", "Test Work")
	writer.WriteField("description", "Test Description")
	writer.Close()

	req := httptest.NewRequest(http.MethodPost, "/work", fileBuffer)
	req.Header.Set("Content-Type", writer.FormDataContentType())
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d", w.Code)
	}

	// --- Storage cleanup ---
	// アップロードパスは PostWork と同じ計算方法
	uploadedPath := userID + "/test.png"
	if err := storage.DeleteFromSupabase(context.Background(), "works", uploadedPath); err != nil {
		t.Fatalf("failed to cleanup storage: %v", err)
	}
}
