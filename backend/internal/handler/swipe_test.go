package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

/*
========================
正常系：スワイプ成功
========================
*/
func TestPostSwipeSuccess(t *testing.T) {
	r := setupTestRouter(withSwipe)

	userA := createTestUser(t)
	userB := createTestUser(t)

	workB := createTestWork(t, userB)

	body := SwipeRequest{
		FromUserID: userA,
		ToWorkID:   workB,
		IsLike:     true,
	}

	b, _ := json.Marshal(body)

	req := httptest.NewRequest(http.MethodPost, "/swipe", bytes.NewBuffer(b))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	// DBに保存されているか
	var count int
	err := db.Pool.QueryRow(
		context.Background(),
		`SELECT COUNT(*) FROM swipes WHERE from_user_id=$1 AND to_work_id=$2`,
		userA, workB,
	).Scan(&count)

	if err != nil {
		t.Fatalf("db check failed: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected 1 swipe, got %d", count)
	}
}

/*
========================
異常系：自分の作品にスワイプ
========================
*/
func TestPostSwipeToOwnWork(t *testing.T) {
	r := setupTestRouter(withSwipe)

	user := createTestUser(t)
	work := createTestWork(t, user)

	body := SwipeRequest{
		FromUserID: user,
		ToWorkID:   work,
		IsLike:     true,
	}

	b, _ := json.Marshal(body)

	req := httptest.NewRequest(http.MethodPost, "/swipe", bytes.NewBuffer(b))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d: %s", w.Code, w.Body.String())
	}
}

/*
========================
正常系：マッチ成立
========================
*/
func TestSwipeCreatesMatch(t *testing.T) {
	r := setupTestRouter(withSwipe)

	userA := createTestUser(t)
	userB := createTestUser(t)

	workA := createTestWork(t, userA)
	workB := createTestWork(t, userB)

	like := func(fromUserID, toWorkID string) {
		body := SwipeRequest{
			FromUserID: fromUserID,
			ToWorkID:   toWorkID,
			IsLike:     true,
		}

		b, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/swipe", bytes.NewBuffer(b))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		if w.Code != http.StatusOK {
			t.Fatalf("like failed: %d %s", w.Code, w.Body.String())
		}
	}

	// 相互いいね
	like(userB, workA)
	like(userA, workB)

	// goroutine の完了待ち
	time.Sleep(300 * time.Millisecond)

	var count int
	err := db.Pool.QueryRow(
		context.Background(),
		`
		SELECT COUNT(*) FROM matches
		WHERE (user1_id=$1 AND user2_id=$2)
		   OR (user1_id=$2 AND user2_id=$1)
		`,
		userA, userB,
	).Scan(&count)

	if err != nil {
		t.Fatalf("db check failed: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected 1 match, got %d", count)
	}
}
