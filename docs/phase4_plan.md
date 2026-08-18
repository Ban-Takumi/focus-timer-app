# クラウド展開 実装計画 (Phase 4)

## 概要と目標
- ローカル環境（`127.0.0.1`）で動作しているFastAPIバックエンドを，クラウド環境へデプロイし，24時間稼働させる．
- ローカルのSQLiteを廃止し，クラウドのPostgreSQLへ移行することで，複数デバイス間でのデータ同期を可能にする．
- SwiftUIアプリ（Mac/iOS）の接続先URLをクラウドへ切り替える．

## 技術スタック選定
就活用のポートフォリオとしても評価が高く，無料で強力なモダンインフラ構成を採用します．
- **データベース:** [Supabase](https://supabase.com/) (PostgreSQL)
  - 理由: 無料枠が充実しており，強力なリレーショナルDB．セットアップが非常に簡単．
- **バックエンド・ホスティング:** [Render](https://render.com/) (Web Service)
  - 理由: FastAPIアプリ（Python）をGitHubリポジトリと連携させて無料で簡単に自動デプロイできるため．

## 実装ステップ

### 1. クラウドデータベースの準備（ユーザー手動操作）
- ユーザー側でSupabaseアカウントを作成し，新しいプロジェクトを立ち上げる．
- 取得したデータベースの接続URL（`DATABASE_URL`）を提供する．

### 2. バックエンドのクラウド対応化（Pythonコード修正）
- ローカル開発環境の `database.py` をPostgreSQL対応に書き換え．
- `psycopg2-binary` 等のPostgreSQL用ドライバを `requirements.txt` に追加．
- 環境変数（`DATABASE_URL`）を利用してDBに接続できるよう，設定管理用のコードを追加する．

### 3. FastAPIのデプロイ（Render連携）
- 変更をGitHubへPushする．
- ユーザー側でRenderアカウントを作成し，GitHubリポジトリと連携して新しい「Web Service」を作成する．
- Renderの環境変数に `DATABASE_URL` を設定し，デプロイを実行する．

### 4. SwiftUIアプリ（フロントエンド）の接続先変更
- `TimerViewModel.swift` および `FocusTimerWidget.swift` 内にハードコードされている `http://127.0.0.1:8000` を，Renderで発行された公開URL（例: `https://focus-timer-api.onrender.com`）に変更する．

---

## 検討事項（Open Questions）
- SupabaseやRenderといったクラウドサービスのアカウント作成に抵抗はありませんか？（完全無料で利用可能なプランを使用します）
- もし既に利用したことがあるクラウドプラットフォーム（AWS, GCP, Heroku, Firebaseなど）があれば，そちらに合わせることも可能です．ご希望はありますか？
