// backend/internal/handler/received_reviews_test.go
package handler

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

/*
========================
正常系：受信レビュー取得
========================
*/
func TestGetReceivedReviewsSuccess(t *testing.T) {
	r := setupTestRouter(withReceivedReviews)

	// --- ユーザー ---
	userA := createTestUser(t)
	userB := createTestUser(t)

	// --- 作品 ---
	workA := createTestWork(t, userA)
	workB := createTestWork(t, userB)

	// --- match ---
	var matchID string
	err := db.Pool.QueryRow(
		context.Background(),
		`
		INSERT INTO public.matches (user1_id, user2_id, work1_id, work2_id)
		VALUES ($1, $2, $3, $4)
		RETURNING id
		`,
		userA, userB, workA, workB,
	).Scan(&matchID)

	if err != nil {
		t.Fatalf("failed to create match: %v", err)
	}

	t.Cleanup(func() {
		db.Pool.Exec(
			context.Background(),
			"DELETE FROM public.matches WHERE id=$1",
			matchID,
		)
	})

	// --- review（A → B）---
	var reviewID string
	err = db.Pool.QueryRow(
		context.Background(),
		`
		INSERT INTO public.reviews (
			match_id,
			from_user_id,
			to_user_id,
			work_id,
			comment
		)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id
		`,
		matchID,
		userA,
		userB,
		workB,
		"nice work!",
	).Scan(&reviewID)

	if err != nil {
		t.Fatalf("failed to create review: %v", err)
	}

	t.Cleanup(func() {
		db.Pool.Exec(
			context.Background(),
			"DELETE FROM public.reviews WHERE id=$1",
			reviewID,
		)
	})

	// --- API 呼び出し ---
	req := httptest.NewRequest(
		http.MethodGet,
		"/reviews?user_id="+userB,
		nil,
	)

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	// --- レスポンス検証 ---
	var resp []ReceivedReviewResponse
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to parse response: %v", err)
	}

	if len(resp) != 1 {
		t.Fatalf("expected 1 review, got %d", len(resp))
	}

	review := resp[0]

	if review.MatchID != matchID {
		t.Fatalf("unexpected match_id: %s", review.MatchID)
	}
	if review.UserID != userA {
		t.Fatalf("unexpected user_id: %s", review.UserID)
	}
	if review.WorkID != workB {
		t.Fatalf("unexpected work_id: %s", review.WorkID)
	}
	if review.Comment != "nice work!" {
		t.Fatalf("unexpected comment: %s", review.Comment)
	}

	// URL が組み立てられているか
	if review.IconURL == "" || review.WorkImageURL == "" {
		t.Fatal("icon_url or work_image_url is empty")
	}
}
