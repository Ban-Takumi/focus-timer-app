//
//  FocusTimerWidget.swift
//  FocusTimerWidget
//
//  Created by Takumi Ban on 2026/06/25.
//

import WidgetKit
import SwiftUI
import Charts

// APIレスポンス解析用の構造体
struct DailyStat: Decodable, Identifiable {
    let date: String
    let total_duration_minutes: Int
    var id: String { date }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), todayDuration: 0, weeklyStats: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        // プレビュー表示用のダミーデータ
        let dummyStats = [
            DailyStat(date: "2026-07-05", total_duration_minutes: 25),
            DailyStat(date: "2026-07-06", total_duration_minutes: 50),
            DailyStat(date: "2026-07-07", total_duration_minutes: 0),
            DailyStat(date: "2026-07-08", total_duration_minutes: 100),
            DailyStat(date: "2026-07-09", total_duration_minutes: 75),
            DailyStat(date: "2026-07-10", total_duration_minutes: 25),
            DailyStat(date: "2026-07-11", total_duration_minutes: 125)
        ]
        let entry = SimpleEntry(date: Date(), todayDuration: 125, weeklyStats: dummyStats)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // テスト環境の場合は http://127.0.0.1:8000/stats/weekly に変更してください。
        guard let url = URL(string: "https://focus-timer-app-6u58.onrender.com/stats/weekly") else {
            let entry = SimpleEntry(date: Date(), todayDuration: 0, weeklyStats: [])
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
            completion(timeline)
            return
        }

        // バックエンドから1週間の統計を取得
        URLSession.shared.dataTask(with: url) { data, response, error in
            var stats: [DailyStat] = []
            var todayDuration = 0
            
            if let data = data, let decoded = try? JSONDecoder().decode([DailyStat].self, from: data) {
                stats = decoded
                
                // 今日の日付のデータを検索して取得
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let todayString = formatter.string(from: Date())
                
                if let todayStat = stats.first(where: { $0.date == todayString }) {
                    todayDuration = todayStat.total_duration_minutes
                } else {
                    todayDuration = 0
                }
            }
            
            let entry = SimpleEntry(date: Date(), todayDuration: todayDuration, weeklyStats: stats)
            // 次の更新タイミング（15分後）を設定
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }.resume()
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let todayDuration: Int
    let weeklyStats: [DailyStat]
}

struct FocusTimerWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium, .systemLarge:
            WeeklyChartWidgetView(entry: entry)
        case .systemExtraLarge:
            ExtraLargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// 従来のSmallサイズのウィジェットUI
struct SmallWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日の集中時間")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                let hours = entry.todayDuration / 60
                let minutes = entry.todayDuration % 60
                
                Text("\(hours)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                Text("時間")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 2)
                
                Text("\(minutes)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                Text("分")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// 新しいチャート表示用のUI (Medium / Large用)
struct WeeklyChartWidgetView: View {
    var entry: Provider.Entry
    
    // 曜日ごとに色を判定する関数
    func colorForDateString(_ dateStr: String) -> Color {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return .orange }
        
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
    
    // 日付文字列を「月」「火」のような曜日文字列に変換する関数
    func weekdayString(from dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return "" }
        
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("今週の集中時間")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            if entry.weeklyStats.isEmpty {
                Text("データがありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart {
                    ForEach(entry.weeklyStats) { stat in
                        BarMark(
                            x: .value("曜日", weekdayString(from: stat.date)),
                            y: .value("集中時間(分)", stat.total_duration_minutes)
                        )
                        .foregroundStyle(colorForDateString(stat.date))
                        .annotation(position: .top) {
                            Text("\(stat.total_duration_minutes)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// Extra Large用のUI (左に今週のグラフ、右に今日の時間を配置)
struct ExtraLargeWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        HStack(spacing: 24) {
            WeeklyChartWidgetView(entry: entry)
                .frame(maxWidth: .infinity)
            
            Divider()
            
            SmallWidgetView(entry: entry)
                .frame(maxWidth: .infinity)
        }
    }
}

struct FocusTimerWidget: Widget {
    let kind: String = "FocusTimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(macOS 14.0, iOS 17.0, *) {
                FocusTimerWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                FocusTimerWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Focus Timer")
        .description("今日の集中時間や今週の推移を表示します。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

#Preview(as: .systemMedium) {
    FocusTimerWidget()
} timeline: {
    SimpleEntry(date: .now, todayDuration: 125, weeklyStats: [
        DailyStat(date: "2026-07-05", total_duration_minutes: 25),
        DailyStat(date: "2026-07-06", total_duration_minutes: 50),
        DailyStat(date: "2026-07-07", total_duration_minutes: 0),
        DailyStat(date: "2026-07-08", total_duration_minutes: 100),
        DailyStat(date: "2026-07-09", total_duration_minutes: 75),
        DailyStat(date: "2026-07-10", total_duration_minutes: 25),
        DailyStat(date: "2026-07-11", total_duration_minutes: 125)
    ])
}

// ----------------------------------------------------
// ゴール専用ウィジェット (達成度を % で表示)
// ----------------------------------------------------

struct GoalWidgetView: View {
    var entry: Provider.Entry
    @AppStorage("dailyFocusGoalMinutes", store: UserDefaults(suiteName: "group.com.bantakumi.FocusTimer")) var dailyFocusGoalMinutes: Int = 120
    
    var body: some View {
        ZStack {
            let percentage = (CGFloat(entry.todayDuration) / CGFloat(max(1, dailyFocusGoalMinutes))) * 100
            let progress = min(percentage / 100, 1.0)
            
            Circle()
                .stroke(lineWidth: 12)
                .opacity(0.2)
                .foregroundColor(.orange)
            
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                .foregroundColor(.orange)
                .rotationEffect(Angle(degrees: 270.0))
            
            VStack(spacing: 4) {
                Text("今日の達成度")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(Int(percentage))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
            }
        }
        .padding(12)
    }
}

struct FocusGoalWidget: Widget {
    let kind: String = "FocusGoalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(macOS 14.0, iOS 17.0, *) {
                GoalWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                GoalWidgetView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Focus Goal")
        .description("今日の目標達成度をパーセントで表示します。")
        .supportedFamilies([.systemSmall])
    }
}
