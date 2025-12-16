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
// Supabase Storage の works バケットにアップロードする関数
func UploadToSupabase(
	ctx context.Context, // リクエストの寿命・キャンセル管理用（Gin から渡す）
	fileHeader *multipart.FileHeader, // フォームで送られてきた画像ファイルのメタ情報
	path string, // works バケット内の保存パス（例: works/{userId}/{uuid}.png）
) error {

	// ① multipart.FileHeader から実際のファイルを開く
	file, err := fileHeader.Open()
	if err != nil {
		return err
	}
	defer file.Close()

	// ② ファイルの中身をすべてメモリに読み込む
	// （画像サイズが極端に大きくない前提）
	data, err := io.ReadAll(file)
	if err != nil {
		return err
	}

	// ③ Supabase Storage のアップロード先 URL を作る
	// /storage/v1/object/{bucket}/{path}
	url := fmt.Sprintf(
		"%s/storage/v1/object/works/%s",
		os.Getenv("SUPABASE_URL"), // https://xxxx.supabase.co
		path,                      // works/{userId}/{filename}
	)

	// ④ HTTP POST リクエストを作成
	// body に画像データをそのまま載せる
	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		url,
		bytes.NewReader(data),
	)
	if err != nil {
		return err
	}

	// ⑤ 認証ヘッダー
	// Service Role Key を使うことで
	// RLS や bucket の制限を無視してアップロードできる（※バックエンド限定）
	req.Header.Set(
		"Authorization",
		"Bearer "+os.Getenv("SUPABASE_SERVICE_ROLE_KEY"),
	)

	// ⑥ Content-Type を元ファイルのものに合わせる
	// image/png, image/jpeg など
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
	// 300以上はエラーとして扱う
	if res.StatusCode >= 300 {
		return fmt.Errorf("upload failed: %s", res.Status)
	}

	// ⑨ 正常終了
	return nil
}
