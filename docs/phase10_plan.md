# Phase 10: タイマー終了時の自動ポップオーバー表示

## 目的
タイマー（集中時間や休憩時間）が終了したタイミングで、ユーザーが手動でメニューバーアイコンをクリックしなくても、自動的にポップオーバーを開いて知らせるようにします。これにより、タイマーの終了を見逃すことを防ぎ、次のアクション（休憩に入る、または作業に戻る）へスムーズに移行できるようにします。

## 要件
1. タイマーのカウントダウンが0になった瞬間に、UIが自動的に表示されること。
2. アプリがバックグラウンドにいる（他のアプリを操作している）場合でも、手前にポップオーバーが表示されること。
3. 既存の `TimerViewModel` と `AppDelegate` をクリーンに連携させること（密結合を避けるため、NotificationCenterを利用）。

## 実装ステップ
1. **通知の定義 (`TimerViewModel.swift` または新規ファイル)**
   - `Notification.Name` の拡張として `timerDidFinish` などのカスタム通知名を定義する。
2. **通知の発行 (`TimerViewModel.swift`)**
   - `timerFinished()` メソッド内で、タイマーが0になった際に `NotificationCenter.default.post` を使って通知を送信する。
3. **通知の受信と表示 (`FocusTimerApp.swift` / `AppDelegate`)**
   - `applicationDidFinishLaunching` 内で `NotificationCenter` のオブザーバーを登録し、通知をリッスンする。
   - 通知を受け取った際に実行されるメソッド (`@objc func handleTimerFinished()`) を作成する。
   - メソッド内で、`NSApp.activate(ignoringOtherApps: true)` を呼び出してアプリをアクティブにする。
   - すでにポップオーバーが開いていないか確認し、開いていなければ `popover.show(...)` を呼び出してポップオーバーを表示する。
