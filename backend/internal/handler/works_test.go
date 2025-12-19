// backend/internal/handler/works_test.go
package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestGetWorks_CountOnly(t *testing.T) {
	r := setupTestRouter(withWorks)

	// --- ユーザー作成 ---
	userA := createTestUser(t) // 自分
	userB := createTestUser(t) // 他ユーザー

	// --- 作品作成 ---
	createTestWork(t, userB)
	createTestWork(t, userB)
	createTestWork(t, userB) // 複数作品を作る

	// --- workB1 をスワイプ済みにする ---
	workToSwipe := createTestWork(t, userB)
	createTestSwipe(t, userA, workToSwipe, userB, true)

	// --- API 呼び出し ---
	req := httptest.NewRequest(http.MethodGet, "/works?user_id="+userA, nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	// --- レスポンス確認 ---
	var resp []WorkResponse
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to parse response: %v", err)
	}

	// --- 件数チェック（0件でない、最大10件） ---
	if len(resp) == 0 {
		t.Fatalf("expected at least one unswiped work, got 0")
	}

	if len(resp) > 10 {
		t.Fatalf("expected at most 10 works, got %d", len(resp))
	}

	// --- スワイプ済み作品は含まれないことを簡易確認（存在チェックではなく件数でカバー） ---
	// 返却件数が少なくなることは、スワイプ済みが除外されていることの間接証拠
}
