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

// UploadWorksFromLocal はローカルの画像フォルダから
// Supabase Storage にアップロードし、DBに登録する関数
func UploadWorksFromLocal() {
	// ローカルの assets/works フォルダを読み込む
	files, err := os.ReadDir("assets/works")
	if err != nil {
		log.Fatal("failed to read local works folder:", err)
	}

	for _, f := range files {
		if f.IsDir() {
			continue // ディレクトリは無視
		}

		localPath := filepath.Join("assets/works", f.Name())

		// ファイル名からメールアドレスを推定
		//    例: user_001.png → user_001@example.com
		base := strings.TrimSuffix(f.Name(), filepath.Ext(f.Name()))
		email := base + "@example.com"

		// DB から正しい userID (UUID) を取得
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
		storagePath := fmt.Sprintf("works/%s/%s%s", userID, uuid.New().String(), filepath.Ext(f.Name()))

		// ファイルを開く
		file, err := os.Open(localPath)
		if err != nil {
			log.Printf("failed to open %s: %v", f.Name(), err)
			continue
		}

		// Supabase にアップロード
		if err := storage.UploadLocalFileToSupabase(context.Background(), file, "works", storagePath); err != nil {
			log.Printf("failed to upload %s: %v", f.Name(), err)
			file.Close()
			continue
		}
		file.Close()
	}
}
