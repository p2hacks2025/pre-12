package batch

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/google/uuid"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
	"github.com/p2hacks2025/pre-12/backend/internal/storage"
)

// UploadIconsFromLocal はローカルの icons フォルダから
// Supabase Storage にアップロードし、users.icon_url を更新する関数
func UploadIconsFromLocal() {
	// ローカルの assets/icons フォルダを読み込む
	files, err := os.ReadDir("assets/icons")
	if err != nil {
		log.Fatal("failed to read local icons folder:", err)
	}

	for _, f := range files {
		if f.IsDir() {
			continue
		}

		localPath := filepath.Join("assets/icons", f.Name())

		// ファイル名からメールアドレスを推定
		// 例: user_001.png → user_001@example.com
		base := strings.TrimSuffix(f.Name(), filepath.Ext(f.Name()))
		email := base + "@example.com"

		// userID を取得
		var userID string
		err := db.Pool.QueryRow(
			context.Background(),
			"SELECT id FROM users WHERE email = $1",
			email,
		).Scan(&userID)
		if err != nil {
			log.Printf("failed to get user id for %s: %v", f.Name(), err)
			continue
		}

		// Supabase Storage 上のパス
		storagePath := fmt.Sprintf(
			"icons/%s/%s%s",
			userID,
			uuid.New().String(),
			filepath.Ext(f.Name()),
		)

		file, err := os.Open(localPath)
		if err != nil {
			log.Printf("failed to open %s: %v", f.Name(), err)
			continue
		}

		// アップロード
		if err := storage.UploadLocalFileToSupabase(
			context.Background(),
			file,
			storagePath,
		); err != nil {
			log.Printf("failed to upload %s: %v", f.Name(), err)
			file.Close()
			continue
		}
		file.Close()
	}
}
