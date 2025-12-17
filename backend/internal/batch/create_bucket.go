package batch

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
)

// CreateBucketIfNotExists は指定したバケットが存在しない場合に作成する
func CreateBucketIfNotExists(bucketName string, isPublic bool) error {
	supabaseURL := os.Getenv("SUPABASE_URL")
	serviceKey := os.Getenv("SUPABASE_SERVICE_ROLE_KEY")

	// バケット作成のリクエストボディ
	body := map[string]interface{}{
		"id":     bucketName,
		"name":   bucketName,
		"public": isPublic,
	}
	jsonBody, _ := json.Marshal(body)

	url := fmt.Sprintf("%s/storage/v1/bucket", supabaseURL)
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBody))
	if err != nil {
		return err
	}

	req.Header.Set("Authorization", "Bearer "+serviceKey)
	req.Header.Set("Content-Type", "application/json")

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()

	resBody, _ := io.ReadAll(res.Body)

	// 200 or 201 なら作成成功
	if res.StatusCode == 200 || res.StatusCode == 201 {
		log.Printf("bucket '%s' created successfully", bucketName)
		return nil
	}

	// 409 または "Duplicate" が含まれていれば既に存在
	if res.StatusCode == 409 || strings.Contains(string(resBody), "Duplicate") || strings.Contains(string(resBody), "already exists") {
		log.Printf("bucket '%s' already exists", bucketName)
		return nil
	}

	return fmt.Errorf("failed to create bucket '%s': %s - %s", bucketName, res.Status, string(resBody))
}
