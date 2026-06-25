//
//  ContentView.swift
//  FocusTimer
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TimerViewModel()
    
    // 残り時間を "MM:SS" の形式にする
    var timeString: String {
        let minutes = viewModel.timeRemaining / 60
        let seconds = viewModel.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Focus Timer")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(timeString)
                .font(.system(size: 80, weight: .medium, design: .monospaced))
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
                        .background(viewModel.isRunning ? Color.orange : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
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
            }
        }
        .padding()
        // ウィンドウの最小サイズを指定（Mac用）
        .frame(minWidth: 300, minHeight: 300)
    }
}

#Preview {
    ContentView()
}
