import SwiftUI

/// プリセット新規追加シート画面
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
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 350, height: 250)
    }
}
