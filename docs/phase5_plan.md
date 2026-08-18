# Phase 5: アプリ機能の拡充（ポモドーロサイクルの導入）

## 目的
現在の「25分固定」のタイマーを拡張し、ポモドーロ・テクニックの基本である「25分の集中 → 5分の休憩」のサイクルをアプリ内でシームレスに回せるようにする。

## 要件
1. **モード管理**
   - 「Focus（集中）」と「Break（休憩）」の2つのモードを定義する。
   - アプリ起動時の初期状態は「Focus」モード。
2. **時間の切り替え**
   - Focusモード：25分（25 * 60秒）
   - Breakモード：5分（5 * 60秒）
3. **サイクル進行（手動スタート）**
   - Focusタイマー（25分）が0になった時、自動でBreakモードに切り替わり時間は5分にセットされる。カウントダウンは**自動スタートせず**、ユーザーがStartボタンを押すまで待機する（ご要望通り「動的（手動でのトリガー）」とする）。
   - Breakタイマー（5分）が0になった時、自動でFocusモードに切り替わり時間は25分にセットされる。同じく手動スタート待機。
4. **記録の送信**
   - Focusモード（25分）が完走した時のみ、バックエンドへ記録（POST `/records/`）を送信し、ウィジェットを更新する。
   - Breakモード（5分）が完走した時は記録を送信しない（休憩は作業時間に含まないため）。
5. **UIの変更（お任せ部分）**
   - モードに応じて画面上部のテキストを変更（`Focus Time` / `Break Time`）。
   - 視覚的に「今は休憩中だ」と直感的にわかるように、Breakモード中はリラックスできる寒色系（青やシアンなど）にボタンやアクセントカラーを変化させる。

## 変更予定のファイル

### 1. `FocusTimer/FocusTimer/TimerViewModel.swift`
- `enum TimerMode { case focus, breakTime }` の追加。
- `@Published var mode: TimerMode = .focus` の追加。
- `focusTime` (25分) と `breakTime` (5分) の定数定義。
- `timerFinished()` 内で `mode` を判定するロジックの追加：
  - Focus完了時: `saveRecord()` を呼び出し、`mode = .breakTime`、時間を5分にセット。
  - Break完了時: 記録はせず `mode = .focus`、時間を25分にセット。

### 2. `FocusTimer/FocusTimer/ContentView.swift`
- 画面上部のタイトルテキストを `viewModel.mode == .focus ? "Focus Time" : "Break Time"` に動的変更。
- Start/Pause ボタンの色をモードに合わせて変更。
  - Focus中: 今まで通り（Start: 緑, Pause: オレンジ）。
  - Break中: 休憩用の色（Start: 青, Pause: 水色など）。

---
※ 本ファイルは設計書です。ユーザーの承認（GOサイン）を得たのち、実際の実装（コードの書き換え）に移行します。
