package batch

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/p2hacks2025/pre-12/backend/internal/db"
	"github.com/p2hacks2025/pre-12/backend/internal/storage"
)

// UploadWorksFromLocal はローカルの画像フォルダから
// Supabase Storage にアップロードし、DBに登録する関数
func UploadWorksFromLocal() {
	files, err := os.ReadDir("assets/works")
	if err != nil {
		log.Fatal("failed to read local works folder:", err)
	}

	for _, f := range files {
		if f.IsDir() {
			continue
		}

		localPath := filepath.Join("assets/works", f.Name())

		base := strings.TrimSuffix(f.Name(), filepath.Ext(f.Name()))
		email := base + "@example.com"

		var userID string
		err := db.Pool.QueryRow(context.Background(), "SELECT id FROM users WHERE email = $1", email).Scan(&userID)
		if err != nil {
			log.Printf("failed to get user id for %s: %v", f.Name(), err)
			continue
		}

		newPath := fmt.Sprintf("%s/%s", userID, f.Name())

		file, err := os.Open(localPath)
		if err != nil {
			log.Printf("failed to open %s: %v", f.Name(), err)
			continue
		}

		// PUT で上書き
		if err := storage.UploadLocalFileToSupabase(context.Background(), file, "works", newPath, "PUT"); err != nil {
			log.Printf("failed to upload %s: %v", f.Name(), err)
			file.Close()
			continue
		}
		file.Close()
	}
}
