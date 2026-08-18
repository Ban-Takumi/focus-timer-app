import Foundation

/// アプリケーション全体の設定・定数
enum AppConfig {
    /// バックエンド API のベース URL
    static let baseURL = "https://focus-timer-app-6u58.onrender.com"
    // ローカルテスト時は以下に切り替え可能
    // static let baseURL = "http://127.0.0.1:8000"
    
    /// App Group 識別子（Widget とのデータ共有用）
    static let appGroupID = "group.com.fukutaku.FocusTimer"
    
    /// デフォルトの1日集中目標（分）
    static let defaultDailyFocusGoalMinutes: Int = 120
    
    /// AppStorage のキー名
    enum StorageKey {
        static let dailyFocusGoalMinutes = "dailyFocusGoalMinutes"
    }
}
