//backend/internal/handler/auth_test.go

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

func TestLoginSuccess(t *testing.T) {
	// 必要な API だけを持つルーター
	r := setupTestRouter(withSignup, withLogin)

	// --- ユーザー作成 ---
	email := fmt.Sprintf("login_test_%d@example.com", time.Now().UnixNano())
	password := "password123"

	signupBody := SignupRequest{
		Username: "login_test",
		Email:    email,
		Password: password,
	}

	b1, _ := json.Marshal(signupBody)
	reqSignup := httptest.NewRequest(http.MethodPost, "/sign-up", bytes.NewBuffer(b1))
	reqSignup.Header.Set("Content-Type", "application/json")

	wSignup := httptest.NewRecorder()
	r.ServeHTTP(wSignup, reqSignup)

	if wSignup.Code != http.StatusCreated {
		t.Fatalf("signup failed: %s", wSignup.Body.String())
	}

	var signupResp struct {
		UserID string `json:"user_id"`
	}
	json.Unmarshal(wSignup.Body.Bytes(), &signupResp)

	t.Cleanup(func() {
		db.Pool.Exec(
			context.Background(),
			"DELETE FROM public.users WHERE id=$1",
			signupResp.UserID,
		)
	})

	// --- ログイン ---
	loginBody := map[string]string{
		"email":    email,
		"password": password,
	}
	b2, _ := json.Marshal(loginBody)

	reqLogin := httptest.NewRequest(http.MethodPost, "/login", bytes.NewBuffer(b2))
	reqLogin.Header.Set("Content-Type", "application/json")

	wLogin := httptest.NewRecorder()
	r.ServeHTTP(wLogin, reqLogin)

	if wLogin.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d, body=%s", wLogin.Code, wLogin.Body.String())
	}
}
