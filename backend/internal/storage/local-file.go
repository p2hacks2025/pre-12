package storage

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
)

// UploadLocalFileToSupabase はローカル画像ファイルを Supabase Storage にアップロードする
func UploadLocalFileToSupabase(
	ctx context.Context,
	file *os.File,
	bucket string,
	path string,
) error {
	ext := filepath.Ext(file.Name())
	contentType := "application/octet-stream"
	switch ext {
	case ".png":
		contentType = "image/png"
	case ".jpg", ".jpeg":
		contentType = "image/jpeg"
	case ".gif":
		contentType = "image/gif"
	}

	url := fmt.Sprintf(
		"%s/storage/v1/object/%s/%s",
		os.Getenv("SUPABASE_URL"),
		bucket,
		path,
	)

	req, err := http.NewRequestWithContext(ctx, http.MethodPut, url, file)
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
		body, _ := io.ReadAll(res.Body)
		return fmt.Errorf("upload failed (%s): %s - %s", bucket, res.Status, string(body))
	}

	// 成功したら printf で出力
	fmt.Printf("uploaded successfully: bucket=%s, path=%s\n", bucket, path)

	return nil
}
