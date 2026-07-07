//
//  ContentView.swift
//  FocusTimer
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TimerViewModel()
    
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
