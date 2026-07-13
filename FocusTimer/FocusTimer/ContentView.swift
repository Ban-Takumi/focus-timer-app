//
//  ContentView.swift
//  FocusTimer
//

import SwiftUI
import Charts

struct ContentView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    init(viewModel: TimerViewModel = TimerViewModel()) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        TabView {
            TimerView(viewModel: viewModel)
                .tabItem {
                    Label("タイマー", systemImage: "timer")
                }
            
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
                
            StatisticsView(viewModel: viewModel)
                .tabItem {
                    Label("統計", systemImage: "chart.bar")
                }
        }
        // ウィンドウの最小サイズを指定（Mac用）
        .frame(minWidth: 350, minHeight: 400)
    }
}

struct TimerView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    // 残り時間を "MM:SS" の形式にする
    var timeString: String {
        let minutes = viewModel.timeRemaining / 60
        let seconds = viewModel.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.mode.rawValue)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(viewModel.mode == .focus ? .primary : .blue)
            
            if let preset = viewModel.selectedPreset {
                Text("Preset: \(preset.name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(timeString)
                .font(.system(size: 80, weight: .medium, design: .monospaced))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding()
            
            HStack(spacing: 20) {
                Button(action: {
                    if viewModel.isRunning {
                        viewModel.stop()
                    } else {
                        viewModel.start()
                    }
                }) {
                    Text(viewModel.isRunning ? "Pause" : "Start")
                        .font(.title2)
                        .frame(width: 100, height: 40)
                        .background(viewModel.isRunning ? Color.orange : (viewModel.mode == .focus ? Color.green : Color.blue))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    viewModel.reset()
                }) {
                    Text("Reset")
                        .font(.title2)
                        .frame(width: 100, height: 40)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

struct StatisticsView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                DailyTimelineChartView(viewModel: viewModel)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("今週の集中時間")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    if viewModel.weeklyStats.isEmpty {
                Text("データがありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(viewModel.weeklyStats, id: \.date) { stat in
                    BarMark(
                        x: .value("Day", formatDay(from: stat.date)),
                        y: .value("Minutes", stat.total_duration_minutes)
                    )
                    .foregroundStyle(colorForDateString(stat.date))
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .padding()
            }
                }
                .padding(.vertical)
                .onAppear {
                    viewModel.fetchWeeklyStats()
                }
            }
        }
    }
    
    // 日付文字列（YYYY-MM-DD）から曜日や日を取り出す補助メソッド
    private func formatDay(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ja_JP")
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "ja_JP")
        displayFormatter.dateFormat = "E" // 例: 月, 火
        return displayFormatter.string(from: date)
    }
    
    // 曜日ごとに色を変える
    private func colorForDateString(_ dateString: String) -> Color {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return .blue }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
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

struct DailyTimelineChartView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日のタイムライン")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            if viewModel.todayTimeline.isEmpty {
                Text("データがありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 50)
            } else {
                Chart {
                    // 背景のトラック（24時間分）
                    BarMark(
                        xStart: .value("Start", timelineDomain().lowerBound),
                        xEnd: .value("End", timelineDomain().upperBound),
                        y: .value("Category", "集中時間")
                    )
                    .foregroundStyle(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                    
                    ForEach(viewModel.todayTimeline) { record in
                        let start = record.createdAtDate
                        let end = start.addingTimeInterval(TimeInterval(record.duration_minutes * 60))
                        
                        BarMark(
                            xStart: .value("Start", start),
                            xEnd: .value("End", end),
                            y: .value("Category", "集中時間")
                        )
                        .foregroundStyle(.blue)
                        .cornerRadius(4)
                    }
                }
                .chartXScale(domain: timelineDomain(), range: .plotDimension(padding: 20))
                .chartXAxis {
                    let axisDates = axisValues()
                    AxisMarks(values: axisDates) { value in
                        if let date = value.as(Date.self) {
                            let isFirst = date == axisDates.first
                            let isLast = date == axisDates.last
                            let anchor: UnitPoint = isFirst ? .topLeading : (isLast ? .topTrailing : .top)
                            
                            AxisValueLabel(anchor: anchor) {
                                if isLast {
                                    Text("7:59")
                                } else {
                                    Text(formatTime(date))
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 50)
                .padding(.horizontal)
            }
        }
        .padding(.top)
        .onAppear {
            viewModel.fetchTimeline()
        }
    }
    
    private func timelineDomain() -> ClosedRange<Date> {
        let now = Date()
        let calendar = Calendar.current
        var start: Date
        if calendar.component(.hour, from: now) < 8 {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
            start = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: yesterday) ?? now
        } else {
            start = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
        }
        let end = calendar.date(byAdding: .hour, value: 24, to: start) ?? now
        return start...end
    }
    
    private func axisValues() -> [Date] {
        let start = timelineDomain().lowerBound
        let calendar = Calendar.current
        return [
            start,
            calendar.date(byAdding: .hour, value: 8, to: start)!,
            calendar.date(byAdding: .hour, value: 16, to: start)!,
            calendar.date(byAdding: .hour, value: 24, to: start)!
        ]
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: date)
    }
}


