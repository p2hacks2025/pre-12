package batch

import (
	"context"
	"log"
	"os"

	"github.com/p2hacks2025/pre-12/backend/internal/storage"
)

// UploadDefaultIcon はデフォルトアイコンを
// Supabase Storage (icons/default.png) にアップロードする
func UploadDefaultIcon() {
	localPath := "assets/icons/default.png"

	file, err := os.Open(localPath)
	if err != nil {
		log.Fatal("failed to open default icon:", err)
	}
	defer file.Close()

	// Storage 上の固定パス
	const bucket = "icons"
	const storagePath = "default.png"

	// PUT で上書き
	if err := storage.UploadLocalFileToSupabase(context.Background(), file, bucket, storagePath); err != nil {
		log.Fatal("failed to upload default icon:", err)
	}

	log.Println("default icon uploaded successfully")
}
