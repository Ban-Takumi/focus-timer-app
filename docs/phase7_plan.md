# Phase 7: グラフウィジェットの追加 (SwiftUI Charts)

## 目的
FocusTimerアプリのウィジェット機能を拡張し、現在の「今日の合計時間」だけでなく、過去7日間の集中時間の推移を視覚的に把握できる棒グラフウィジェット（MediumおよびLargeサイズ）を追加します。これにより、ユーザーのモチベーション維持と振り返りをサポートします。

## 要件
1. **バックエンドの集計API追加**
   - データベース（`PomodoroRecord`）から今日を含む過去7日間の記録を取得し、日ごとに合計集中時間を集計して返すエンドポイントを作成する。
2. **ウィジェットの複数サイズ対応**
   - 既存の `FocusTimerWidget` を拡張し、Small（小）、Medium（中）、Large（大）の3サイズに対応させる。
   - `Small` サイズ：これまで通り「今日の合計時間」のみをシンプルに表示。
   - `Medium` / `Large` サイズ：過去7日間の推移を棒グラフで表示する。
3. **SwiftUI Chartsの導入**
   - `Charts` フレームワークをウィジェットターゲットに導入し、`BarMark` を用いて日別の集中時間をグラフ描画する。
   - ご要望に合わせて、**棒グラフの色を「曜日ごと」に異なる色で描画**するよう実装する。

## 変更予定のファイル

### 1. バックエンド (`backend/`)
- **`backend/schemas.py`**:
  - 日別データモデル `DailyStat` と、1週間分のリストを返す `WeeklyStatsResponse` スキーマを追加。
- **`backend/main.py`**:
  - `GET /stats/weekly` エンドポイントを追加。
  - `datetime` モジュールを用いて過去7日間の日付リストを生成し、対象期間の記録を集計してJSONで返却するロジックを実装。

### 2. ウィジェット拡張 (`FocusTimer/FocusTimerWidget/`)
- **`FocusTimerWidget.swift`**:
  - `StatsResponse` 構造体を拡張し、日別の配列を受け取れるように変更。
  - `Provider` の `getTimeline` 内でフェッチするURLを `/stats/today` から `/stats/weekly` に変更。
  - `FocusTimerWidgetEntryView` に `@Environment(\.widgetFamily) var family` を追加し、サイズ (`family`) に応じてUIを切り分ける。
  - `Charts` をインポートし、Medium / Large 時の `Chart` 描画ビューを追加。
  - `FocusTimerWidget` の `StaticConfiguration` にて `.supportedFamilies([.systemSmall, .systemMedium, .systemLarge])` を有効化。

## 確認事項・注意事項
- グラフの色合いやデザインに特定の希望がある場合は、実装前にすり合わせを行います。（デフォルトではオレンジ色を基調とした棒グラフとします）
- ウィジェットで用いるSwiftUI Chartsは、iOS 16 / macOS 13以降で動作します。（現在のプロジェクトのターゲットOS設定に準拠します）
- バックエンドのAPI変更が含まれるため、ローカルでの動作確認後、Render等の本番環境への再デプロイが必要になります。
