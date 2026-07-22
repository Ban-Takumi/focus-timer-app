import Foundation
import Combine
import WidgetKit
import EventKit

extension Notification.Name {
    static let timerDidFinish = Notification.Name("timerDidFinish")
}

enum TimerMode: String {
    case focus = "Focus Time"
    case breakTime = "Break Time"
}

struct TimerPreset: Identifiable, Codable, Hashable {
    var id: Int?
    var name: String
    var focus_minutes: Int
    var break_minutes: Int
}

struct DailyStat: Codable, Hashable {
    let date: String
    let total_duration_minutes: Int
}

struct TimelineRecord: Codable, Hashable, Identifiable {
    let id: Int
    let task_name: String
    let duration_minutes: Int
    let date: String
    let created_at: String
    
    var createdAtDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: created_at) { return date }
        
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: created_at) ?? Date()
    }
}


class TimerViewModel: ObservableObject {
    @Published var mode: TimerMode = .focus
    @Published var timeRemaining: Int = 50 * 60
    @Published var isRunning: Bool = false
    @Published var currentTaskName: String = ""
    
    @Published var presets: [TimerPreset] = []
    @Published var weeklyStats: [DailyStat] = []
    @Published var todayTimeline: [TimelineRecord] = []

    
    @Published var selectedPreset: TimerPreset? {
        didSet {
            if let preset = selectedPreset, !isRunning {
                focusTime = preset.focus_minutes * 60
                breakTime = preset.break_minutes * 60
                if mode == .focus {
                    timeRemaining = focusTime
                } else {
                    timeRemaining = breakTime
                }
            }
        }
    }
    
    @Published var focusTime: Int = 50 * 60
    @Published var breakTime: Int = 10 * 60
    
    private var timer: AnyCancellable?
    
    // ベースURL: 本番（Render）環境
    private let baseURL = "https://focus-timer-app-6u58.onrender.com"
    // ローカルテスト時は以下に切り替え
    // private let baseURL = "http://127.0.0.1:8000"
    
    init() {
        fetchPresets()
    }
    
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
        
        // タイマー終了の通知を発行
        NotificationCenter.default.post(name: .timerDidFinish, object: nil)
        
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
    
    // バックエンドからプリセットを取得
    func fetchPresets() {
        guard let url = URL(string: "\(baseURL)/presets/") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("プリセット取得エラー: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode([TimerPreset].self, from: data)
                DispatchQueue.main.async {
                    self?.presets = decoded
                    // デフォルトプリセットをセット (未選択の場合のみ。学習:50分/10分を優先)
                    if self?.selectedPreset == nil {
                        if let defaultPreset = decoded.first(where: { $0.name == "学習" }) {
                            self?.selectedPreset = defaultPreset
                        } else if let firstPreset = decoded.first {
                            self?.selectedPreset = firstPreset
                        }
                    }
                }
            } catch {
                print("プリセットデコードエラー: \(error)")
            }
        }.resume()
    }
    
    // バックエンドにプリセットを作成
    func createPreset(name: String, focusMinutes: Int, breakMinutes: Int) {
        guard let url = URL(string: "\(baseURL)/presets/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let presetData: [String: Any] = [
            "name": name,
            "focus_minutes": focusMinutes,
            "break_minutes": breakMinutes
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: presetData, options: [])
        } catch {
            print("エンコードエラー: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("通信エラー: \(error)")
                return
            }
            self?.fetchPresets()
        }.resume()
    }

    // プリセットを削除
    func deletePreset(id: Int) {
        guard let url = URL(string: "\(baseURL)/presets/\(id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("削除エラー: \(error)")
                return
            }
            self?.fetchPresets()
        }.resume()
    }
    
    // バックエンドへ記録を送信
    private func saveRecord() {
        guard let url = URL(string: "\(baseURL)/records/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 送信するデータ（スキーマに合わせて作成）
        let recordData: [String: Any] = [
            "task_name": currentTaskName.isEmpty ? (selectedPreset?.name ?? "Focus Session") : currentTaskName,
            "duration_minutes": focusTime / 60,
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
    
    // バックエンドから今週の統計を取得
    func fetchWeeklyStats() {
        guard let url = URL(string: "\(baseURL)/stats/weekly") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("統計取得エラー: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode([DailyStat].self, from: data)
                DispatchQueue.main.async {
                    self?.weeklyStats = decoded
                }
            } catch {
                print("統計デコードエラー: \(error)")
            }
        }.resume()
    }
    
    // バックエンドから今日のタイムライン統計を取得
    func fetchTimeline() {
        guard let url = URL(string: "\(baseURL)/stats/timeline") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("タイムライン取得エラー: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode([TimelineRecord].self, from: data)
                DispatchQueue.main.async {
                    self?.todayTimeline = decoded
                }
            } catch {
                print("タイムラインデコードエラー: \(error)")
            }
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

// MARK: - Reminder Manager
class ReminderManager: ObservableObject {
    private let eventStore = EKEventStore()
    
    @Published var reminders: [EKReminder] = []
    @Published var isAuthorized: Bool = false
    
    init() {
        checkAccess()
    }
    
    func checkAccess() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
        case .authorized:
            isAuthorized = true
            fetchReminders()
        case .notDetermined:
            requestAccess()
        default:
            isAuthorized = false
        }
    }
    
    func requestAccess() {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToReminders { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.fetchReminders()
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .reminder) { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.fetchReminders()
                    }
                }
            }
        }
    }
    
    func fetchReminders() {
        guard isAuthorized else { return }
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        eventStore.fetchReminders(matching: predicate) { [weak self] fetchedReminders in
            DispatchQueue.main.async {
                self?.reminders = fetchedReminders ?? []
            }
        }
    }
}
