# mock-backend-go

フロント（Flutter）開発用の簡易モックサーバです。`backend/` とは独立しており、本番バックエンドの進捗に関係なく疎通確認できます。

## できること

- `GET /health` -> `{ "status": "ok" }`
- `POST /login` -> リクエスト `{ "id": "...", "displayName": "..." }`
- `GET /works?user_id=...` -> ホーム画面用の作品一覧（ダミー）
- `POST /swipes`（互換: `POST /swipe`）-> スワイプ送信を受け取り（ログに出力）
- `GET /debug/swipes` -> 受信したスワイプ一覧（確認用）

## 起動

```zsh
cd tools/mock-backend-go
go run ./cmd/mock-server
```

デフォルトは `:8080` で待ち受けます。すでに別のサーバが `8080` を使っている場合は `PORT` を変更します。

```zsh
PORT=8081 go run ./cmd/mock-server
```

## 疎通確認（curl）

```zsh
curl -s http://localhost:8080/health | cat
```

```zsh
curl -s -X POST http://localhost:8080/login \
  -H 'content-type: application/json' \
  -d '{"id":"tanaka-taro","displayName":"田中 太郎"}' | cat
```

## Flutter から接続

`BACKEND_BASE_URL` を `--dart-define` で渡します。

```zsh
cd mobile
flutter run --dart-define=BACKEND_BASE_URL=http://localhost:8080
```

ポートを変えた場合の例:

```zsh
cd mobile
flutter run --dart-define=BACKEND_BASE_URL=http://localhost:8081
```
