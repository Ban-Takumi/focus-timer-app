import SwiftUI

/// アプリ共通の日付フォーマッタおよびテーマカラー設定
enum AppTheme {
    /// yyyy-MM-dd フォーマッタ (スレッドセーフ/キャッシュ用)
    static let dateFormatterYYYYMMDD: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    /// 日本語曜日フォーマッタ
    static let japaneseWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter
    }()
    
    /// 日付文字列（YYYY-MM-DD）から日本語の曜日文字列（月、火など）を返す
    static func formatDay(from dateString: String) -> String {
        guard let date = dateFormatterYYYYMMDD.date(from: dateString) else {
            return dateString
        }
        return japaneseWeekdayFormatter.string(from: date)
    }
    
    /// 曜日（日付文字列ベース）に応じたグラフカラーを返す
    static func colorForDateString(_ dateString: String) -> Color {
        guard let date = dateFormatterYYYYMMDD.date(from: dateString) else {
            return .blue
        }
        
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 1: return .red      // 日
        case 2: return .orange   // 月
        case 3: return .yellow   // 火
        case 4: return .green    // 水
        case 5: return .cyan     // 木
        case 6: return .blue     // 金
        case 7: return .purple   // 土
        default: return .orange
        }
    }
}

// 既存の互換性用拡張
extension DateFormatter {
    static let yyyyMMdd: DateFormatter = AppTheme.dateFormatterYYYYMMDD
}
