package batch

import (
	"context"

	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

func getUserIDByEmail(ctx context.Context, email string) string {
	var id string
	_ = db.Pool.QueryRow(ctx,
		`SELECT id FROM users WHERE email=$1`,
		email,
	).Scan(&id)
	return id
}

func getOneWorkID(ctx context.Context, userID string) string {
	var id string
	_ = db.Pool.QueryRow(ctx,
		`SELECT id FROM works WHERE user_id=$1 LIMIT 1`,
		userID,
	).Scan(&id)
	return id
}

func insertLike(ctx context.Context, fromUserID, toWorkID string) {
	_, _ = db.Pool.Exec(ctx, `
		INSERT INTO swipes (from_user_id, to_work_id, to_work_user_id, is_like)
		SELECT $1, w.id, w.user_id, true
		FROM works w
		WHERE w.id = $2 AND w.user_id <> $1
		ON CONFLICT (from_user_id, to_work_id) DO UPDATE
		SET is_like = true, created_at = now()
	`, fromUserID, toWorkID)
}
