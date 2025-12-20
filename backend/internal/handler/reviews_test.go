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

	// --- API 呼び出し ---
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

	// WorkTitle はテスト用に取得して比較（createTestWork で作成したタイトルを知っていればここで比較可能）
	// ここでは簡単のため "test work" プレフィックスで存在確認
	if review.WorkTitle == "" {
		t.Fatal("work_title is empty")
	}
}
