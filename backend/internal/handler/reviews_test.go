// backend/internal/handler/received_reviews_test.go
package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestGetReceivedReviewsSuccess(t *testing.T) {
	r := setupTestRouter(withReceivedReviews)

	// --- ユーザー作成 ---
	userA := createTestUser(t)
	userB := createTestUser(t)

	// --- 作品作成 ---
	workA := createTestWork(t, userA)
	workB := createTestWork(t, userB)

	// --- match 作成 ---
	matchID := createTestMatch(t, userA, userB, workA, workB)

	// --- review 作成（A → B）---
	_ = createTestReview(t, matchID, userA, userB, workB, "nice work!")

	// --- review 作成（B → A）← ★これを追加 ---
	_ = createTestReview(t, matchID, userB, userA, workA, "thanks!")

	// --- API 呼び出し（B が受信レビューを取得）---
	req := httptest.NewRequest(http.MethodGet, "/reviews?user_id="+userB, nil)
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

	// ★ 相互レビュー成立 → 1件返る
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

	if review.IconURL == "" || review.WorkImageURL == "" {
		t.Fatal("icon_url or work_image_url is empty")
	}
	if review.WorkTitle == "" {
		t.Fatal("work_title is empty")
	}
}
