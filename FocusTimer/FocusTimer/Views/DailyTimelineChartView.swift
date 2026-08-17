import SwiftUI
import Charts

/// 今日の詳細タイムライン（朝8:00〜翌朝7:59）チャート表示コンポーネント
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
                        .foregroundStyle(by: .value("Task", record.task_name))
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
