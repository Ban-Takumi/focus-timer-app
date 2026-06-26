//
//  FocusTimerWidget.swift
//  FocusTimerWidget
//
//  Created by Takumi Ban on 2026/06/25.
//

import WidgetKit
import SwiftUI

// APIレスポンス解析用の構造体
struct StatsResponse: Decodable {
    let date: String
    let total_duration_minutes: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), totalDuration: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), totalDuration: 25)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        guard let url = URL(string: "https://focus-timer-app-6u58.onrender.com/stats/today") else {
            let entry = SimpleEntry(date: Date(), totalDuration: 0)
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
            completion(timeline)
            return
        }

        // バックエンドから今日の統計を取得
        URLSession.shared.dataTask(with: url) { data, response, error in
            var duration = 0
            if let data = data, let stats = try? JSONDecoder().decode(StatsResponse.self, from: data) {
                duration = stats.total_duration_minutes
            }
            
            let entry = SimpleEntry(date: Date(), totalDuration: duration)
            // 次の更新タイミング（15分後）を設定
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }.resume()
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let totalDuration: Int
}

struct FocusTimerWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日の集中時間")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .lastTextBaseline) {
                Text("\(entry.totalDuration)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                Text("分")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
        .description("今日の合計集中時間を表示します．")
    }
}
