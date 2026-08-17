import SwiftUI
import Charts

/// 統計画面コンポーネント
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
                                x: .value("Day", AppTheme.formatDay(from: stat.date)),
                                y: .value("Minutes", stat.total_duration_minutes)
                            )
                            .foregroundStyle(AppTheme.colorForDateString(stat.date))
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
}
