package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestGetMatches_Safe(t *testing.T) {
	r := setupTestRouter(withMatches)

	// 1. ユーザー作成
	user1ID := createTestUser(t)
	user2ID := createTestUser(t)

	// 2. 作品作成
	work1ID := createTestWork(t, user1ID)
	work2ID := createTestWork(t, user2ID)

	// 3. マッチ作成
	matchID := createTestMatch(t, user1ID, user2ID, work1ID, work2ID)

	// 4. GET /matches
	req := httptest.NewRequest(http.MethodGet, "/matches?user_id="+user1ID, nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}

	// 5. JSON デコード
	var matches []MatchResponse
	if err := json.Unmarshal(w.Body.Bytes(), &matches); err != nil {
		t.Fatalf("failed to unmarshal: %v", err)
	}

	// 6. 作成した matchID が含まれているか確認
	found := false
	for _, m := range matches {
		if m.MatchID == matchID {
			found = true

			// 相手ユーザー
			if m.UserID != user2ID {
				t.Fatalf("expected userID %s, got %s", user2ID, m.UserID)
			}

			// 基本フィールド
			if m.Username == "" || m.IconURL == "" || m.WorkImageURL == "" || m.WorkTitle == "" {
				t.Fatalf("expected non-empty fields, got %+v", m)
			}

			// ★ 追加チェック：まだレビューしていない
			if m.IsReviewed {
				t.Fatalf("expected is_reviewed=false, got true")
			}

			break
		}
	}

	if !found {
		t.Fatalf("expected match ID %s not found in response", matchID)
	}
}

func TestGetMatches_Reviewed(t *testing.T) {
	r := setupTestRouter(withMatches)

	user1ID := createTestUser(t)
	user2ID := createTestUser(t)

	work1ID := createTestWork(t, user1ID)
	work2ID := createTestWork(t, user2ID)

	matchID := createTestMatch(t, user1ID, user2ID, work1ID, work2ID)

	// user1 → user2 にレビュー
	_ = createTestReview(t, matchID, user1ID, user2ID, work2ID, "great!")

	req := httptest.NewRequest(http.MethodGet, "/matches?user_id="+user1ID, nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}

	var matches []MatchResponse
	_ = json.Unmarshal(w.Body.Bytes(), &matches)

	for _, m := range matches {
		if m.MatchID == matchID {
			if !m.IsReviewed {
				t.Fatalf("expected is_reviewed=true, got false")
			}
			return
		}
	}

	t.Fatalf("match not found")
}
