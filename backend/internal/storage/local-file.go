package storage

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
)

// UploadLocalFileToSupabase はローカル画像ファイルを Supabase にアップロード
func UploadLocalFileToSupabase(ctx context.Context, file *os.File, path string) error {
	// ファイル拡張子から Content-Type を決定
	ext := filepath.Ext(file.Name())
	contentType := "application/octet-stream" // デフォルト
	switch ext {
	case ".png":
		contentType = "image/png"
	case ".jpg", ".jpeg":
		contentType = "image/jpeg"
	case ".gif":
		contentType = "image/gif"
	}

	url := fmt.Sprintf("%s/storage/v1/object/works/%s", os.Getenv("SUPABASE_URL"), path)

	// ファイルを直接 Body に渡す（ストリーミング）
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, file)
	if err != nil {
		return err
	}

	req.Header.Set("Authorization", "Bearer "+os.Getenv("SUPABASE_SERVICE_ROLE_KEY"))
	req.Header.Set("Content-Type", contentType)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()

	if res.StatusCode >= 300 {
		return fmt.Errorf("upload failed: %s", res.Status)
	}

	return nil
}
