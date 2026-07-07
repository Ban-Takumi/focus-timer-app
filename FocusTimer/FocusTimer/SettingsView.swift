import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    @State private var isShowingAddAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("プリセットを選択")) {
                    List {
                        ForEach(viewModel.presets) { preset in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(preset.name)
                                        .font(.headline)
                                    Text("集中: \(preset.focus_minutes)分 / 休憩: \(preset.break_minutes)分")
                                        .font(.subheadline)
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
                        }
                        .onDelete(perform: deletePresets)
                    }
                }
                
                Section(header: Text("新しいプリセットを追加")) {
                    Button(action: {
                        isShowingAddAlert = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("プリセットを追加...")
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $isShowingAddAlert) {
                AddPresetView(viewModel: viewModel, isPresented: $isShowingAddAlert)
            }
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
        NavigationView {
            Form {
                Section(header: Text("プリセット名")) {
                    TextField("例: 読書", text: $name)
                }
                
                Section(header: Text("時間設定 (分)")) {
                    Stepper("集中時間: \(focusMinutes)分", value: $focusMinutes, in: 1...120)
                    Stepper("休憩時間: \(breakMinutes)分", value: $breakMinutes, in: 1...60)
                }
            }
            .navigationTitle("新規作成")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if !name.isEmpty {
                            viewModel.createPreset(name: name, focusMinutes: focusMinutes, breakMinutes: breakMinutes)
                            isPresented = false
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
            .padding()
            .frame(minWidth: 300, minHeight: 300)
        }
    }
}
