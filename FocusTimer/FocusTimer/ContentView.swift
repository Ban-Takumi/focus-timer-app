import SwiftUI

/// メインウィンドウのタブコンテナ画面
@MainActor
struct ContentView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    init(viewModel: TimerViewModel) {
        self.viewModel = viewModel
    }
    
    init() {
        self.viewModel = TimerViewModel()
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

#Preview {
    ContentView()
}
