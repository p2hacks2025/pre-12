package storage

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
)

// UploadToSupabase は
// multipart/form-data で受け取った画像ファイルを
// 指定された Supabase Storage バケットにアップロードする関数
func UploadToSupabase(
	ctx context.Context, // リクエストの寿命・キャンセル管理用（Gin から渡す）
	fileHeader *multipart.FileHeader, // フォームで送られてきた画像ファイルのメタ情報
	bucket string, // バケット名（例: works, icons）
	path string, // バケット内の保存パス（例: {userId}/{uuid}.png）
) error {

	// ① multipart.FileHeader から実際のファイルを開く
	file, err := fileHeader.Open()
	if err != nil {
		return err
	}
	defer file.Close()

	// ② ファイルの中身をすべてメモリに読み込む
	data, err := io.ReadAll(file)
	if err != nil {
		return err
	}

	// ③ Supabase Storage のアップロード先 URL を作る
	// /storage/v1/object/{bucket}/{path}
	url := fmt.Sprintf(
		"%s/storage/v1/object/%s/%s",
		os.Getenv("SUPABASE_URL"), // https://xxxx.supabase.co
		bucket,                    // 指定バケット
		path,                      // バケット内のパス
	)

	// ④ HTTP POST リクエストを作成
	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPut,
		url,
		bytes.NewReader(data),
	)
	if err != nil {
		return err
	}

	// ⑤ 認証ヘッダー
	req.Header.Set(
		"Authorization",
		"Bearer "+os.Getenv("SUPABASE_SERVICE_ROLE_KEY"),
	)

	// ⑥ Content-Type を元ファイルのものに合わせる
	req.Header.Set(
		"Content-Type",
		fileHeader.Header.Get("Content-Type"),
	)

	// ⑦ リクエスト送信
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()

	// ⑧ ステータスコードチェック
	if res.StatusCode >= 300 {
		return fmt.Errorf("upload failed: %s", res.Status)
	}

	// ⑨ 正常終了
	return nil
}

// DeleteFromSupabase は指定バケット内のファイルを削除する
func DeleteFromSupabase(ctx context.Context, bucket, path string) error {
	url := fmt.Sprintf("%s/storage/v1/object/%s/%s", os.Getenv("SUPABASE_URL"), bucket, path)

	req, err := http.NewRequestWithContext(ctx, http.MethodDelete, url, nil)
	if err != nil {
		return err
	}

	req.Header.Set("Authorization", "Bearer "+os.Getenv("SUPABASE_SERVICE_ROLE_KEY"))

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()

	if res.StatusCode >= 300 {
		return fmt.Errorf("delete failed: %s", res.Status)
	}

	return nil
}
