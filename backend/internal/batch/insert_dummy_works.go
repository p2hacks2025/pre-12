package batch

import (
	"context"
	"log"
	"strings"

	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

// InsertDummyWorks は works テーブルにダミーデータを挿入する関数
func InsertDummyWorks() {
	works := []struct {
		UserEmail   string
		ImageFile   string // ファイル名だけ
		Title       string
		Description string
	}{
		{"user_001@example.com", "user_001.png", "Sunset Landscape", "A beautiful sunset over the mountains."},
		{"user_002@example.com", "user_002.png", "Cute Cat", "A sketch of a cute cat playing."},
		{"user_003@example.com", "user_003.png", "City Night", "Night view of a bustling city."},
		{"user_004@example.com", "user_004.png", "Mountain Hike", "Photo from my last hiking trip."},
	}

	ctx := context.Background()
	for _, w := range works {
		// user_id を取得
		var userID string
		err := db.Pool.QueryRow(ctx, "SELECT id FROM public.users WHERE email = $1", w.UserEmail).Scan(&userID)
		if err != nil {
			log.Printf("failed to get user id for %s: %v", w.UserEmail, err)
			continue
		}

		// image_path を works/{userID}/{filename} にする
		imagePath := strings.Join([]string{"works", userID, w.ImageFile}, "/")

		// works テーブルに挿入
		_, err = db.Pool.Exec(
			ctx,
			`INSERT INTO public.works (user_id, image_path, title, description)
			 VALUES ($1, $2, $3, $4)
			 ON CONFLICT (user_id, image_path) DO NOTHING`,
			userID, imagePath, w.Title, w.Description,
		)
		if err != nil {
			log.Printf("failed to insert work for %s: %v", w.UserEmail, err)
			continue
		}

		log.Printf("inserted work for user: %s, title: %s, image_path: %s", w.UserEmail, w.Title, imagePath)
	}
}
