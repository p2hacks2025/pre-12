package service

import (
	"context"

	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

// CheckAndCreateMatch はマッチ判定を行い、成立すれば matches に保存する
// goroutine から呼ばれる前提
func CheckAndCreateMatch(fromUserID, toWorkID string) {
	ctx := context.Background()

	// 作品の作者IDを取得
	var toWorkUserID string
	err := db.Pool.QueryRow(ctx,
		`SELECT user_id FROM works WHERE id=$1`, toWorkID,
	).Scan(&toWorkUserID)
	if err != nil {
		return
	}

	// 相手が自分の作品にいいねしているか
	var otherWorkID string
	err = db.Pool.QueryRow(ctx, `
		SELECT to_work_id
		FROM swipes
		WHERE from_user_id=$1
		  AND to_work_user_id=$2
		  AND is_like=true
	`, toWorkUserID, fromUserID).Scan(&otherWorkID)

	if err != nil {
		return
	}

	// user_id の順序を固定
	user1, user2 := fromUserID, toWorkUserID
	work1, work2 := toWorkID, otherWorkID
	if user2 < user1 {
		user1, user2 = user2, user1
		work1, work2 = work2, work1
	}

	// マッチ作成（重複は無視）
	_, _ = db.Pool.Exec(ctx, `
		INSERT INTO matches (user1_id, user2_id, work1_id, work2_id)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT DO NOTHING
	`, user1, user2, work1, work2)
}
