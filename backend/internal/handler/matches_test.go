package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

// TestGetMatches_Safe は /matches エンドポイントのテスト。
// DB に他のマッチがあっても安全に動作するように修正。
func TestGetMatches_Safe(t *testing.T) {
	r := setupTestRouter(withMatches)

	// 1. ユーザー作成（相手も含めて2人）
	user1ID := createTestUser(t)
	user2ID := createTestUser(t)

	// 2. 作品作成
	work1ID := createTestWork(t, user1ID)
	work2ID := createTestWork(t, user2ID)

	// 3. マッチ作成
	matchID := createTestMatch(t, user1ID, user2ID, work1ID, work2ID)

	// 4. GET /matches?user_id=...
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

	// 6. 作成した matchID がレスポンスに含まれているか確認
	found := false
	for _, m := range matches {
		if m.MatchID == matchID {
			found = true
			// 必要ならさらに各フィールドの検証も可能
			if m.UserID != user2ID {
				t.Fatalf("expected userID %s, got %s", user2ID, m.UserID)
			}
			if m.Username == "" || m.IconURL == "" || m.WorkImageURL == "" {
				t.Fatalf("expected non-empty username/icon/workImage, got %+v", m)
			}
			break
		}
	}
	if !found {
		t.Fatalf("expected match ID %s not found in response", matchID)
	}
}
