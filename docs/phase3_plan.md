# SwiftUI Widget 実装計画 (Phase 3)

Macのデスクトップ（またはiOSのホーム画面）に表示するウィジェットの実装計画．

## 概要と目標
- WidgetKitを使用し，ホーム画面にポモドーロの統計データを表示するウィジェットを構築．
- FastAPIバックエンドの `/stats/today` エンドポイントから今日の合計集中時間を取得．
- 取得したデータを視覚的にわかりやすいUI（Widget）で表示．

## 実装ステップ

### 1. Widget Extensionの追加（ユーザー手動操作）
Xcode上でのターゲット追加が必要．以下の手順でWidget Extensionを追加．
- Xcodeのメニューから `File` > `New` > `Target...` を選択．
- `Widget Extension` を検索して選択．
- **Product Name:** `FocusTimerWidget` (任意)
- **Include Configuration Intent:** チェックを外す（シンプルな静的ウィジェットとするため）
- `Finish` を押し，スキームのアクティベートを求められたら `Activate` を選択．

### 2. データ取得ロジック（Provider）の実装
ウィジェットにデータを提供する `TimelineProvider` を実装．
- `getTimeline` メソッド内で，URLSessionを用いて `http://127.0.0.1:8000/stats/today` へGETリクエストを送信．
- 取得したJSONデータをデコードし，今日の合計時間（`total_duration_minutes`）を抽出．
- 取得したデータを保持する `SimpleEntry` 構造体を更新．

### 3. ウィジェットUI（View）の実装
ウィジェットの見た目を定義するビューを実装．
- 今日の日付と，合計集中時間（分）を表示．
- シンプルで美しいデザイン（フォントサイズ，余白，背景色など）の調整．

### 4. Sandbox設定の更新
ウィジェット側からもローカルのAPIへ通信するため，ウィジェットのターゲット設定画面（Signing & Capabilities）にてApp Sandboxの `Outgoing Connections (Client)` を有効化．

---

## 検討事項（Open Questions）
- バックエンドのURLはアプリ本体と同じく `http://127.0.0.1:8000` 固定で問題ないか？
- ウィジェットのデザイン（色やアイコン，表示形式など）に特定の希望はあるか？
