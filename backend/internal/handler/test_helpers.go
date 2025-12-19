// backend/internal/handler/test_helpers.go
package handler

import (
	"context"
	"fmt"
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
	var workID string
	err := db.Pool.QueryRow(
		context.Background(),
		`
		INSERT INTO public.works (user_id, title, image_path)
		VALUES ($1, $2, $3)
		RETURNING id
		`,
		userID,
		"test work",
		"/dummy/test.png",
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
