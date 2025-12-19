// backend/internal/handler/test_helpers.go
package handler

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

/*
========================
DB helpers only
========================
*/

type CleanupT interface {
	Fatalf(string, ...any)
	Cleanup(func())
}

func createTestUser(t CleanupT) string {
	email := fmt.Sprintf("test_%d@example.com", time.Now().UnixNano())

	var userID string
	err := db.Pool.QueryRow(
		context.Background(),
		`
		INSERT INTO public.users (username, email, password)
		VALUES ($1, $2, 'dummy')
		RETURNING id
		`,
		"testuser", email,
	).Scan(&userID)

	if err != nil {
		t.Fatalf("failed to create user: %v", err)
	}

	t.Cleanup(func() {
		_, _ = db.Pool.Exec(
			context.Background(),
			"DELETE FROM public.users WHERE id=$1",
			userID,
		)
	})

	return userID
}

func createTestWork(t CleanupT, userID string) string {
	// image_path をユニークにする
	imagePath := fmt.Sprintf("/dummy/test_%d.png", time.Now().UnixNano())
	title := fmt.Sprintf("test work %d", time.Now().UnixNano()) // タイトルも必要ならユニーク化

	var workID string
	err := db.Pool.QueryRow(
		context.Background(),
		`
		INSERT INTO public.works (user_id, title, image_path)
		VALUES ($1, $2, $3)
		RETURNING id
		`,
		userID,
		title,
		imagePath,
	).Scan(&workID)

	if err != nil {
		t.Fatalf("failed to create work: %v", err)
	}

	t.Cleanup(func() {
		_, _ = db.Pool.Exec(
			context.Background(),
			"DELETE FROM public.works WHERE id=$1",
			workID,
		)
	})

	return workID
}

// createTestSwipe はスワイプ済みレコードを作成
func createTestSwipe(t testing.TB, fromUserID, toWorkID, toWorkUserID string, isLike bool) string {
	var swipeID string
	err := db.Pool.QueryRow(
		context.Background(),
		`
        INSERT INTO public.swipes (from_user_id, to_work_id, to_work_user_id, is_like)
        VALUES ($1, $2, $3, $4)
        RETURNING id
        `,
		fromUserID, toWorkID, toWorkUserID, isLike,
	).Scan(&swipeID)

	if err != nil {
		t.Fatalf("failed to create swipe: %v", err)
	}

	t.Cleanup(func() {
		_, _ = db.Pool.Exec(context.Background(), "DELETE FROM public.swipes WHERE id=$1", swipeID)
	})

	return swipeID
}
