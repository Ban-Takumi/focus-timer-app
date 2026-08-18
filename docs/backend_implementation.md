# Phase 1: バックエンド（Python/FastAPI）実装内容

本ドキュメントでは、ポモドーロ・タイマーアプリのPhase 1で実装されたバックエンド（データの受け皿）の仕様と構成についてまとめます。

## 技術スタック

*   **言語:** Python 3.x
*   **フレームワーク:** FastAPI
*   **データベース:** SQLite
*   **ORM:** SQLAlchemy
*   **データバリデーション:** Pydantic
*   **サーバー:** Uvicorn

## ディレクトリ構成 (`backend/`)

```text
backend/
├── database.py       # データベースの接続設定（SQLAlchemy Engine/Session）
├── main.py           # FastAPIアプリケーション本体、APIエンドポイントの定義
├── models.py         # SQLAlchemyを用いたDBテーブルモデルの定義
├── schemas.py        # Pydanticを用いたAPIのリクエスト・レスポンスの型定義
└── requirements.txt  # 必要なPythonパッケージのリスト
```

## データベース設計

バックエンドではSQLiteデータベース (`pomodoro.db`) を使用します。

### `records` テーブル (PomodoroRecord)

ポモドーロタイマーの1回の集中セッションを記録するテーブルです。

| カラム名           | データ型    | 説明                                 |
| ------------------ | ----------- | ------------------------------------ |
| `id`               | Integer     | 主キー（自動採番）                   |
| `task_name`        | String      | 実行したタスクの名前                 |
| `duration_minutes` | Integer     | 集中した時間（分単位、通常25分など） |
| `date`             | Date        | 記録された日付（集計用）             |
| `created_at`       | DateTime    | レコードの作成日時（自動設定）       |

## API 仕様

FastAPIによって以下のREST APIエンドポイントが提供されます。

### 1. サーバー状態確認
*   **エンドポイント:** `GET /`
*   **説明:** サーバーが正常に起動しているかを確認するためのテスト用API。
*   **レスポンス例:**
    ```json
    {
      "message": "Pomodoro Timer API is running!"
    }
    ```

### 2. ポモドーロ記録の保存
*   **エンドポイント:** `POST /records/`
*   **説明:** タイマー終了時に、新しいポモドーロの記録をデータベースに保存します。
*   **リクエストボディ (JSON):**
    ```json
    {
      "task_name": "タスク名",
      "duration_minutes": 25,
      "date": "YYYY-MM-DD"
    }
    ```
*   **レスポンス:** 保存されたレコードの情報（IDや作成日時を含む）を返します。

### 3. 今日の統計データ取得
*   **エンドポイント:** `GET /stats/today`
*   **説明:** サーバーの現在日付において、保存されているすべての `duration_minutes` を合計して返します。これはウィジェット（Phase 3）に表示するためのデータとして使用されます。
*   **レスポンス例:**
    ```json
    {
      "date": "2026-06-24",
      "total_duration_minutes": 150
    }
    ```

### 4. 記録一覧の取得（デバッグ用）
*   **エンドポイント:** `GET /records/`
*   **説明:** データベースに保存されている記録のリストを取得します。クエリパラメータで `skip` や `limit` を指定してページネーションが可能です。

## 開発・実行方法

### 仮想環境の構築と起動

```bash
cd backend
# 仮想環境の作成
python3 -m venv .venv
# 仮想環境のアクティベート（Mac）
source .venv/bin/activate
# 依存パッケージのインストール
pip install -r requirements.txt
```

### サーバーの起動

```bash
uvicorn main:app --reload
```

サーバー起動後、ブラウザで `http://127.0.0.1:8000/docs` にアクセスすると、Swagger UIによって自動生成されたインタラクティブなAPIドキュメントを閲覧・テストすることができます。
