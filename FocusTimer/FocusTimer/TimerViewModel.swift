import Foundation
import Combine
import WidgetKit

enum TimerMode: String {
    case focus = "Focus Time"
    case breakTime = "Break Time"
}

class TimerViewModel: ObservableObject {
    @Published var mode: TimerMode = .focus
    @Published var timeRemaining: Int = 25 * 60
    @Published var isRunning: Bool = false
    
    private var timer: AnyCancellable?
    private let focusTime: Int = 25 * 60
    private let breakTime: Int = 5 * 60
    
    // タイマー開始
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timerFinished()
                }
            }
    }
    
    // タイマー停止
    func stop() {
        isRunning = false
        timer?.cancel()
        timer = nil
    }
    
    // タイマーリセット
    func reset() {
        stop()
        timeRemaining = mode == .focus ? focusTime : breakTime
    }
    
    // 0になったときの処理
    private func timerFinished() {
        stop()
        
        if mode == .focus {
            // 集中モード終了：記録を保存し、休憩モードへ移行
            saveRecord()
            mode = .breakTime
            timeRemaining = breakTime
        } else {
            // 休憩モード終了：集中モードへ戻る（記録はしない）
            mode = .focus
            timeRemaining = focusTime
        }
    }
    
    // バックエンドへ記録を送信
    private func saveRecord() {
        guard let url = URL(string: "https://focus-timer-app-6u58.onrender.com/records/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 送信するデータ（スキーマに合わせて作成）
        let recordData: [String: Any] = [
            "task_name": "Focus Session",
            "duration_minutes": 25,
            "date": DateFormatter.yyyyMMdd.string(from: Date())
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: recordData, options: [])
        } catch {
            print("JSONエンコードエラー: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("通信エラー: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("ステータスコード: \(httpResponse.statusCode)")
            }
            
            // 通信成功後にウィジェットの表示を強制的に更新（リロード）する
            WidgetCenter.shared.reloadAllTimelines()
            
        }.resume()
    }
}

// DateFormatterの拡張（日付用）
extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
