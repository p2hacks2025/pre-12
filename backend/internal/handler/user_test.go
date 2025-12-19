package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

func TestGetMyProfileSuccess(t *testing.T) {
	// 必要なエンドポイントだけを持つルーター
	r := setupTestRouter(withSignup, withMe)

	// --- ユーザー作成 ---
	body := SignupRequest{
		Username: "profile_test",
		Email:    fmt.Sprintf("profile_test_%d@example.com", time.Now().UnixNano()),
		Password: "password123",
	}

	b, _ := json.Marshal(body)
	reqSignup := httptest.NewRequest(http.MethodPost, "/sign-up", bytes.NewBuffer(b))
	reqSignup.Header.Set("Content-Type", "application/json")

	wSignup := httptest.NewRecorder()
	r.ServeHTTP(wSignup, reqSignup)

	if wSignup.Code != http.StatusCreated {
		t.Fatalf("signup failed: %s", wSignup.Body.String())
	}

	var resp struct {
		UserID string `json:"user_id"`
	}
	if err := json.Unmarshal(wSignup.Body.Bytes(), &resp); err != nil {
		t.Fatal("failed to parse response")
	}
	if resp.UserID == "" {
		t.Fatal("user_id is empty")
	}

	t.Cleanup(func() {
		db.Pool.Exec(
			context.Background(),
			"DELETE FROM public.users WHERE id=$1",
			resp.UserID,
		)
	})

	// --- プロフィール取得 ---
	req := httptest.NewRequest(
		http.MethodGet,
		"/me?user_id="+resp.UserID,
		nil,
	)

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}
}
