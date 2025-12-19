name: "🐛 Bug report"
description: "不具合の報告"
title: "[Bug]: "
labels: ["bug"]
body:
  - type: markdown
    attributes:
      value: |
        できるだけ再現手順を具体的に書いてください。スクショやログがあると助かります。

  - type: textarea
    id: summary
    attributes:
      label: 概要
      description: 何が起きているか
      placeholder: 例）ログイン後、プロフィール画面でクラッシュする
    validations:
      required: true

  - type: textarea
    id: steps
    attributes:
      label: 再現手順
      description: 手順を番号付きで
      placeholder: |
        1.
        2.
        3.
    validations:
      required: true

  - type: textarea
    id: expected
    attributes:
      label: 期待する挙動
      placeholder: 例）クラッシュせずにプロフィールが表示される
    validations:
      required: true

  - type: textarea
    id: actual
    attributes:
      label: 実際の挙動
      placeholder: 例）画面遷移直後にクラッシュする
    validations:
      required: true

  - type: textarea
    id: env
    attributes:
      label: 環境
      description: OS / ブラウザ / 端末 / バージョンなど
      placeholder: |
        - OS:
        - Browser:
        - Device:
        - App version:
    validations:
      required: false

  - type: textarea
    id: logs
    attributes:
      label: ログ / スクリーンショット
      description: あれば貼ってください
    validations:
      required: false
