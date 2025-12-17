package batch

import (
	"context"
	"log"
	"strings"

	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

// InsertDummyUsers は users テーブルにダミーデータを挿入する関数
func InsertDummyUsers() {
	users := []struct {
		Username string
		Email    string
		Password string
		IconFile string // ファイル名だけ
		Bio      string
	}{
		{"Alice Johnson", "user_001@example.com", "password1", "user_001.png", "Hello, I'm Alice!"},
		{"Bob Smith", "user_002@example.com", "password2", "user_002.png", "I love drawing."},
		{"Charlie Lee", "user_003@example.com", "password3", "user_003.png", "Photography is my hobby."},
		{"Diana King", "user_004@example.com", "password4", "user_004.png", "I enjoy hiking."},
	}

	ctx := context.Background()
	for _, u := range users {
		// まずユーザーを挿入して id を取得
		var userID string
		err := db.Pool.QueryRow(
			ctx,
			`INSERT INTO public.users (username, email, password, bio)
			 VALUES ($1, $2, $3, $4)
			 ON CONFLICT (email) DO NOTHING
			 RETURNING id`,
			u.Username, u.Email, u.Password, u.Bio,
		).Scan(&userID)

		// ON CONFLICT の場合はすでに存在する id を取得
		if err != nil {
			err = db.Pool.QueryRow(ctx, "SELECT id FROM public.users WHERE email = $1", u.Email).Scan(&userID)
			if err != nil {
				log.Printf("failed to get user id for %s: %v", u.Email, err)
				continue
			}
		}

		// icon_path を icons/{userID}/{filename} にする
		iconPath := strings.Join([]string{"icons", userID, u.IconFile}, "/")

		// icon_path を更新
		_, err = db.Pool.Exec(ctx, "UPDATE public.users SET icon_path=$1 WHERE id=$2", iconPath, userID)
		if err != nil {
			log.Printf("failed to update icon_path for %s: %v", u.Email, err)
			continue
		}

		log.Printf("inserted user: %s with icon_path: %s", u.Email, iconPath)
	}
}
