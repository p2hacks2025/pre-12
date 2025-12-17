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

// UploadIconsFromLocal はローカルの icons フォルダから
// Supabase Storage にアップロードし、users.icon_url を更新する関数
func UploadIconsFromLocal() {
	files, err := os.ReadDir("assets/icons")
	if err != nil {
		log.Fatal("failed to read local icons folder:", err)
	}

	for _, f := range files {
		if f.IsDir() || f.Name() == "default.png" {
			continue
		}

		localPath := filepath.Join("assets/icons", f.Name())

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
		if err := storage.UploadLocalFileToSupabase(context.Background(), file, "icons", newPath, "PUT"); err != nil {
			log.Printf("failed to upload %s: %v", f.Name(), err)
			file.Close()
			continue
		}
		file.Close()
	}
}
