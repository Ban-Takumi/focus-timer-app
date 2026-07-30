import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    @State private var isShowingAddAlert = false
    
    var body: some View {
        List {
            Section(header: Text("1日の集中目標").font(.headline)) {
                HStack {
                    Text("目標時間: \(viewModel.dailyFocusGoalMinutes)分")
                    Spacer()
                    Stepper("", value: $viewModel.dailyFocusGoalMinutes, in: 10...1440, step: 10)
                        .labelsHidden()
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
                        Button(role: .destructive) {
                            if let id = preset.id {
                                viewModel.deletePreset(id: id)
                            }
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive, action: {
                            if let id = preset.id {
                                viewModel.deletePreset(id: id)
                            }
                        }) {
                            Label("削除", systemImage: "trash")
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
        .padding()
        .sheet(isPresented: $isShowingAddAlert) {
            AddPresetView(viewModel: viewModel, isPresented: $isShowingAddAlert)
        }
    }
    
    private func deletePresets(offsets: IndexSet) {
        for index in offsets {
            let preset = viewModel.presets[index]
            if let id = preset.id {
                viewModel.deletePreset(id: id)
            }
        }
    }
}

struct AddPresetView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var focusMinutes = 25
    @State private var breakMinutes = 5
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("プリセット名")) {
                    TextField("例: 読書", text: $name)
                }
                
                Section(header: Text("時間設定 (分)")) {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 12) {
                            Stepper("集中時間: \(focusMinutes)分", value: $focusMinutes, in: 1...120)
                            Stepper("休憩時間: \(breakMinutes)分", value: $breakMinutes, in: 1...60)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
            
            HStack {
                Spacer()
                Button("キャンセル") {
                    isPresented = false
                }
                Button("保存") {
                    if !name.isEmpty {
                        viewModel.createPreset(name: name, focusMinutes: focusMinutes, breakMinutes: breakMinutes)
                        isPresented = false
                    }
                }
                .disabled(name.isEmpty)
                // 保存ボタンを強調する（青くする）
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 350, height: 250)
    }
}
