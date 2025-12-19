package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestGetMyWorks_Success(t *testing.T) {
	// --- ルーター登録 ---
	r := setupTestRouter(withMyWorks)

	// --- テスト用ユーザー作成 ---
	userID := createTestUser(t)

	// --- 作品を複数作成 ---
	workID1 := createTestWork(t, userID)
	workID2 := createTestWork(t, userID)

	// --- リクエスト作成 ---
	req := httptest.NewRequest(http.MethodGet, "/my-works?user_id="+userID, nil)
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	// --- ステータスコードチェック ---
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}

	// --- JSON パース ---
	var works []MyWorkResponse
	if err := json.Unmarshal(w.Body.Bytes(), &works); err != nil {
		t.Fatalf("failed to unmarshal: %v", err)
	}

	if len(works) < 2 {
		t.Fatalf("expected at least 2 works, got %d", len(works))
	}

	// --- 作成した作品が含まれているか確認 ---
	found1, found2 := false, false
	for _, w := range works {
		if w.ID == workID1 {
			found1 = true
		}
		if w.ID == workID2 {
			found2 = true
		}
	}

	if !found1 || !found2 {
		t.Fatalf("created works not found in response: found1=%v, found2=%v", found1, found2)
	}
}
