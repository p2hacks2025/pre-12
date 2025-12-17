package storage

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
)

// UploadLocalFileToSupabase はローカル画像ファイルを Supabase Storage にアップロードする
// method: "POST" or "PUT" を指定可能
func UploadLocalFileToSupabase(
	ctx context.Context,
	file *os.File,
	bucket string,
	path string,
	method string, // POST or PUT
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

	// デフォルトで POST にしたい場合は method が空文字なら POST
	if method == "" {
		method = http.MethodPost
	}

	req, err := http.NewRequestWithContext(ctx, method, url, file)
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
		return fmt.Errorf("upload failed (%s): %s", bucket, res.Status)
	}

	return nil
}
