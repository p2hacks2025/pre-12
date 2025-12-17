# mock-backend-go

フロント（Flutter）開発用の簡易モックサーバです。`backend/` とは独立しており、本番バックエンドの進捗に関係なく疎通確認できます。

## できること

- `GET /health` -> `{ "status": "ok" }`
- `POST /login` -> リクエスト `{ "id": "...", "displayName": "..." }`

## 起動

```zsh
cd tools/mock-backend-go
go run ./cmd/mock-server
```

デフォルトは `:8080` で待ち受けます。

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
