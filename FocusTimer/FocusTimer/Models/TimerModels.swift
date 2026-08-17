import Foundation

/// タイマーのモード（集中 / 休憩）
enum TimerMode: String {
    case focus = "Focus Time"
    case breakTime = "Break Time"
}

/// タイマープリセット情報
struct TimerPreset: Identifiable, Codable, Hashable {
    var id: Int?
    var name: String
    var focus_minutes: Int
    var break_minutes: Int
}

/// 日別統計情報
struct DailyStat: Codable, Hashable, Identifiable {
    let date: String
    let total_duration_minutes: Int
    
    var id: String { date }
}

/// タイムラインレコード情報
struct TimelineRecord: Codable, Hashable, Identifiable {
    let id: Int
    let task_name: String
    let duration_minutes: Int
    let date: String
    let created_at: String
    
    /// ISO8601 文字列から Date への変換
    var createdAtDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: created_at) { return date }
        
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: created_at) ?? Date()
    }
}
