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

/*
正常系：サインアップ成功 & cleanup
*/
func TestSignupSuccessAndCleanup(t *testing.T) {
	r := setupTestRouter(withSignup)

	email := fmt.Sprintf("signup_test_%d@example.com", time.Now().UnixNano())

	body := SignupRequest{
		Username: "testuser",
		Email:    email,
		Password: "password123",
	}

	jsonBody, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}

	req := httptest.NewRequest(http.MethodPost, "/sign-up", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", w.Code, w.Body.String())
	}

	var resp struct {
		UserID string `json:"user_id"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatal("failed to parse response")
	}
	if resp.UserID == "" {
		t.Fatal("user_id is empty")
	}

	t.Cleanup(func() {
		if _, err := db.Pool.Exec(
			context.Background(),
			"DELETE FROM public.users WHERE id=$1",
			resp.UserID,
		); err != nil {
			t.Errorf("cleanup failed: %v", err)
		}
	})
}

/*
異常系：メールアドレス重複
*/
func TestSignupEmailAlreadyExists(t *testing.T) {
	r := setupTestRouter(withSignup)

	email := fmt.Sprintf("dup_signup_%d@example.com", time.Now().UnixNano())

	body := SignupRequest{
		Username: "user1",
		Email:    email,
		Password: "password123",
	}

	// --- 1回目（成功） ---
	b1, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}

	req1 := httptest.NewRequest(http.MethodPost, "/sign-up", bytes.NewBuffer(b1))
	req1.Header.Set("Content-Type", "application/json")

	w1 := httptest.NewRecorder()
	r.ServeHTTP(w1, req1)

	if w1.Code != http.StatusCreated {
		t.Fatalf("setup failed: %d %s", w1.Code, w1.Body.String())
	}

	var resp struct {
		UserID string `json:"user_id"`
	}
	if err := json.Unmarshal(w1.Body.Bytes(), &resp); err != nil {
		t.Fatal("failed to parse response")
	}

	t.Cleanup(func() {
		if _, err := db.Pool.Exec(
			context.Background(),
			"DELETE FROM public.users WHERE id=$1",
			resp.UserID,
		); err != nil {
			t.Errorf("cleanup failed: %v", err)
		}
	})

	// --- 2回目（同じメール → 409） ---
	body.Username = "user2"

	b2, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}

	req2 := httptest.NewRequest(http.MethodPost, "/sign-up", bytes.NewBuffer(b2))
	req2.Header.Set("Content-Type", "application/json")

	w2 := httptest.NewRecorder()
	r.ServeHTTP(w2, req2)

	if w2.Code != http.StatusConflict {
		t.Fatalf("expected 409, got %d: %s", w2.Code, w2.Body.String())
	}
}
