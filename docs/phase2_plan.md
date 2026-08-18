# SwiftUI アプリ実装計画 (Phase 2)

このフェーズでは、Mac（およびiOS互換）で動作するタイマーアプリのフロントエンドを構築します。

## 概要と目標
- SwiftUIを使用して、直感的で美しいポモドーロタイマー画面を作成する。
- 25分のカウントダウン機能、およびStart/Stop機能を実装する。
- タイマー完了時に自動的にFastAPIバックエンド（Phase 1で作成）へ記録をPOST送信する。

## 実装ステップ

### 1. プロジェクトの作成（ユーザー手動）
XcodeはGUIでの設定が必要なため、以下の手順でプロジェクトを作成していただきます。
- **テンプレート:** App (macOS または iOS)
- **Product Name:** `FocusTimer` (任意)
- **Interface:** SwiftUI
- **Language:** Swift
- **保存場所:** `/Users/fukusuke/github/focus-timer-app/` の直下に `frontend` または `FocusTimer` ディレクトリとして保存

### 2. タイマーロジック（ViewModel）の実装
状態管理を行う `TimerViewModel` クラスを作成します。
- `ObservableObject` に準拠させ、タイマーの残り時間や状態（実行中か停止中か）を管理します。
- タイマーが0になった際にAPIへ記録を送信するメソッド `saveRecord()` を実装します。
- 通信には標準の `URLSession` を使用します。

### 3. タイマー画面（View）の実装
`ContentView.swift` を編集し、タイマーUIを構築します。
- 中央に大きく残り時間を表示（例: `25:00`）。
- Start / Stop / Reset ボタンの配置。
- （オプション）モダンで美しいデザインにするための色合いやフォントの調整。

---

## 検討事項（Open Questions）
- バックエンドのURLはデフォルトの `http://127.0.0.1:8000` で固定してしまってよいでしょうか？
- タイマーの時間は25分固定でスタートし、UI側でカスタマイズ機能は最初は持たせない（シンプルに保つ）方針でよいでしょうか？
