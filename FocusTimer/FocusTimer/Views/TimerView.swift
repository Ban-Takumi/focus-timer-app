import SwiftUI
import EventKit

/// メインタイマー画面
struct TimerView: View {
    @ObservedObject var viewModel: TimerViewModel
    @StateObject private var reminderManager = ReminderManager()
    var isPopup: Bool = false
    
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
            
            HStack {
                TextField("タスク名を入力...", text: $viewModel.currentTaskName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(viewModel.isRunning)
                
                Menu {
                    if reminderManager.reminders.isEmpty {
                        Text("未完了のタスクなし")
                    } else {
                        ForEach(reminderManager.reminders, id: \.calendarItemIdentifier) { reminder in
                            Button(action: {
                                viewModel.currentTaskName = reminder.title
                            }) {
                                Text(reminder.title)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "list.bullet.rectangle")
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .fixedSize()
                .disabled(viewModel.isRunning)
                .onAppear {
                    reminderManager.fetchReminders()
                }
            }
            .frame(maxWidth: 250)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 13)
                    .opacity(0.2)
                    .foregroundColor(viewModel.mode == .focus ? .blue : .green)
                
                let totalTime = viewModel.mode == .focus ? viewModel.focusTime : viewModel.breakTime
                let progress = totalTime > 0 ? CGFloat(viewModel.timeRemaining) / CGFloat(totalTime) : 0.0
                
                Circle()
                    .trim(from: 1.0 - progress, to: 1.0)
                    .stroke(style: StrokeStyle(lineWidth: 13, lineCap: .round, lineJoin: .round))
                    .foregroundColor(viewModel.mode == .focus ? .blue.opacity(0.7) : .green.opacity(0.7))
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear(duration: 1.0), value: viewModel.timeRemaining)
                
                Text(timeString)
                    .font(.system(size: 75, weight: .medium, design: .monospaced))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .frame(width: 250, height: 250)
            .padding()
            
            VStack(spacing: 15) {
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
                
                if !isPopup && viewModel.mode == .focus {
                    Button(action: {
                        viewModel.completeCurrentTaskAndContinue()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("タスクを完了して次へ")
                        }
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
    }
}
