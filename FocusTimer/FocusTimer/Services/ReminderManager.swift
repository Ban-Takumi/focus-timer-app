import Foundation
import EventKit
import Combine

/// Apple リマインダー連携を管理するクラス
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
