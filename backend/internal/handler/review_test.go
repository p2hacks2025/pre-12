// backend/internal/handler/review_test.go
package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

/*
========================
正常系：レビュー作成成功
========================
*/
func TestPostReviewSuccess(t *testing.T) {
	r := setupTestRouter(withReview)

	// --- ユーザー & 作品 ---
	userA := createTestUser(t)
	userB := createTestUser(t)

	workA := createTestWork(t, userA)
	workB := createTestWork(t, userB)

	// --- match 作成 ---
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

	// --- review API ---
	body := CreateReviewRequest{
		MatchID:    matchID,
		FromUserID: userA,
		Comment:    "great work!",
	}

	b, _ := json.Marshal(body)

	req := httptest.NewRequest(http.MethodPost, "/review", bytes.NewBuffer(b))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", w.Code, w.Body.String())
	}

	// --- DB確認 ---
	var count int
	err = db.Pool.QueryRow(
		context.Background(),
		`
		SELECT COUNT(*) FROM public.reviews
		WHERE match_id=$1 AND from_user_id=$2
		`,
		matchID, userA,
	).Scan(&count)

	if err != nil {
		t.Fatalf("db check failed: %v", err)
	}

	if count != 1 {
		t.Fatalf("expected 1 review, got %d", count)
	}
}
