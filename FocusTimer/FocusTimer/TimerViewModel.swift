import Foundation
import Combine
import WidgetKit
import SwiftUI

extension Notification.Name {
    static let timerDidFinish = Notification.Name("timerDidFinish")
}

@MainActor
class TimerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var mode: TimerMode = .focus
    @Published var timeRemaining: Int = 50 * 60
    @Published var lastSavedTimeRemaining: Int = 50 * 60
    @Published var isRunning: Bool = false
    @Published var currentTaskName: String = ""
    
    @Published var presets: [TimerPreset] = []
    @Published var weeklyStats: [DailyStat] = []
    @Published var todayTimeline: [TimelineRecord] = []
    
    @AppStorage(AppConfig.StorageKey.dailyFocusGoalMinutes, store: UserDefaults(suiteName: AppConfig.appGroupID))
    var dailyFocusGoalMinutes: Int = AppConfig.defaultDailyFocusGoalMinutes
    
    @Published var todayTotalMinutes: Int = 0

    @Published var selectedPreset: TimerPreset? {
        didSet {
            if let preset = selectedPreset, !isRunning {
                focusTime = preset.focus_minutes * 60
                breakTime = preset.break_minutes * 60
                if mode == .focus {
                    timeRemaining = focusTime
                    lastSavedTimeRemaining = focusTime
                } else {
                    timeRemaining = breakTime
                }
            }
        }
    }
    
    @Published var focusTime: Int = 50 * 60
    @Published var breakTime: Int = 10 * 60
    
    // MARK: - Private Properties
    private var timer: AnyCancellable?
    private let apiService = APIService.shared
    
    // MARK: - Initializer
    init() {
        fetchPresets()
    }
    
    // MARK: - Timer Controls
    
    /// タイマーを開始する
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
    
    /// タイマーを一時停止する
    func stop() {
        isRunning = false
        timer?.cancel()
        timer = nil
    }
    
    /// タイマーをリセットする
    func reset() {
        stop()
        timeRemaining = mode == .focus ? focusTime : breakTime
        if mode == .focus {
            lastSavedTimeRemaining = timeRemaining
        }
    }
    
    /// 現在のタスクを完了として記録し、タイマーは止めずに継続する
    func completeCurrentTaskAndContinue() {
        guard mode == .focus else { return }
        
        let elapsed = lastSavedTimeRemaining - timeRemaining
        if elapsed >= 60 {
            saveRecord(elapsedSeconds: elapsed)
        }
        
        lastSavedTimeRemaining = timeRemaining
        currentTaskName = ""
    }
    
    /// カウントダウンが0になったときの終了処理
    private func timerFinished() {
        stop()
        
        // タイマー終了の通知を発行
        NotificationCenter.default.post(name: .timerDidFinish, object: nil)
        
        if mode == .focus {
            // 集中モード終了：記録を保存し、休憩モードへ移行
            let elapsed = lastSavedTimeRemaining - timeRemaining
            if elapsed >= 60 {
                saveRecord(elapsedSeconds: elapsed)
            }
            mode = .breakTime
            timeRemaining = breakTime
        } else {
            // 休憩モード終了：集中モードへ戻る（記録はしない）
            mode = .focus
            timeRemaining = focusTime
            lastSavedTimeRemaining = focusTime
        }
    }
    
    // MARK: - API / Data Actions
    
    /// バックエンドからプリセットを取得
    func fetchPresets() {
        Task {
            do {
                let fetchedPresets = try await apiService.fetchPresets()
                self.presets = fetchedPresets
                
                // デフォルトプリセットをセット (未選択の場合のみ。「学習:50分/10分」を優先)
                if self.selectedPreset == nil {
                    if let defaultPreset = fetchedPresets.first(where: { $0.name == "学習" }) {
                        self.selectedPreset = defaultPreset
                    } else if let firstPreset = fetchedPresets.first {
                        self.selectedPreset = firstPreset
                    }
                }
            } catch {
                print("プリセット取得エラー: \(error.localizedDescription)")
            }
        }
    }
    
    /// 新しいプリセットを作成
    func createPreset(name: String, focusMinutes: Int, breakMinutes: Int) {
        Task {
            do {
                _ = try await apiService.createPreset(name: name, focusMinutes: focusMinutes, breakMinutes: breakMinutes)
                self.fetchPresets()
            } catch {
                print("プリセット作成エラー: \(error.localizedDescription)")
            }
        }
    }

    /// プリセットを削除
    func deletePreset(id: Int) {
        Task {
            do {
                try await apiService.deletePreset(id: id)
                self.fetchPresets()
            } catch {
                print("プリセット削除エラー: \(error.localizedDescription)")
            }
        }
    }
    
    /// バックエンドへポモドーロ記録を送信
    private func saveRecord(elapsedSeconds: Int) {
        let durationMinutes = elapsedSeconds / 60
        let taskName = currentTaskName.isEmpty ? (selectedPreset?.name ?? "Focus Session") : currentTaskName
        
        Task {
            do {
                try await apiService.saveRecord(taskName: taskName, durationMinutes: durationMinutes)
                // 通信成功後にウィジェットの表示を更新
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                print("記録保存エラー: \(error.localizedDescription)")
            }
        }
    }
    
    /// バックエンドから今週の統計を取得
    func fetchWeeklyStats() {
        Task {
            do {
                let stats = try await apiService.fetchWeeklyStats()
                self.weeklyStats = stats
                
                // 今日の合計集中時間を計算
                let todayString = AppTheme.dateFormatterYYYYMMDD.string(from: Date())
                if let todayStat = stats.first(where: { $0.date == todayString }) {
                    self.todayTotalMinutes = todayStat.total_duration_minutes
                } else {
                    self.todayTotalMinutes = 0
                }
            } catch {
                print("統計取得エラー: \(error.localizedDescription)")
            }
        }
    }
    
    /// バックエンドから今日のタイムライン統計を取得
    func fetchTimeline() {
        Task {
            do {
                let timeline = try await apiService.fetchTimeline()
                self.todayTimeline = timeline
            } catch {
                print("タイムライン取得エラー: \(error.localizedDescription)")
            }
        }
    }
}
