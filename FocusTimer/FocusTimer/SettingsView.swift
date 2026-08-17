import SwiftUI
import WidgetKit

/// 設定画面コンポーネント
struct SettingsView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var isShowingAddAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("1日の集中目標").font(.headline)) {
                HStack {
                    Text("目標時間: \(viewModel.dailyFocusGoalMinutes)分")
                    Spacer()
                    Stepper("", value: $viewModel.dailyFocusGoalMinutes, in: 10...1440, step: 10)
                        .labelsHidden()
                        .onChange(of: viewModel.dailyFocusGoalMinutes) { _ in
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("プリセットを選択").font(.headline)) {
                ForEach(viewModel.presets) { preset in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(preset.name)
                                .font(.headline)
                            Text("集中: \(preset.focus_minutes)分 / 休憩: \(preset.break_minutes)分")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if viewModel.selectedPreset?.id == preset.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedPreset = preset
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !isDefaultPreset(preset.name) {
                            Button(role: .destructive) {
                                if let id = preset.id {
                                    viewModel.deletePreset(id: id)
                                }
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                    .contextMenu {
                        if !isDefaultPreset(preset.name) {
                            Button(role: .destructive, action: {
                                if let id = preset.id {
                                    viewModel.deletePreset(id: id)
                                }
                            }) {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section(header: Text("新しいプリセットを追加").font(.headline).padding(.top, 10)) {
                Button(action: {
                    isShowingAddAlert = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("プリセットを追加...")
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .padding()
        .sheet(isPresented: $isShowingAddAlert) {
            AddPresetView(viewModel: viewModel, isPresented: $isShowingAddAlert)
        }
    }
    
    private func isDefaultPreset(_ name: String) -> Bool {
        return ["学習", "ポモドーロ", "ショート"].contains(name)
    }
}
