import Foundation

/// API 通信エラー定義
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです。"
        case .invalidResponse:
            return "サーバーからの応答が無効です。"
        case .httpError(let statusCode):
            return "HTTPエラーが発生しました (ステータスコード: \(statusCode))"
        case .decodingError(let error):
            return "データの解析に失敗しました: \(error.localizedDescription)"
        case .encodingError(let error):
            return "データの作成に失敗しました: \(error.localizedDescription)"
        case .networkError(let error):
            return "通信エラーが発生しました: \(error.localizedDescription)"
        }
    }
}

/// バックエンド API との通信を担当するサービスクラス
actor APIService {
    static let shared = APIService()
    
    private let baseURL: String
    private let session: URLSession
    
    init(baseURL: String = AppConfig.baseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    // MARK: - Presets API
    
    /// プリセット一覧を取得する
    func fetchPresets() async throws -> [TimerPreset] {
        guard let url = URL(string: "\(baseURL)/presets/") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        
        do {
            return try JSONDecoder().decode([TimerPreset].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    /// 新しいプリセットを作成する
    func createPreset(name: String, focusMinutes: Int, breakMinutes: Int) async throws -> TimerPreset {
        guard let url = URL(string: "\(baseURL)/presets/") else {
            throw APIError.invalidURL
        }
        
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
            throw APIError.encodingError(error)
        }
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        do {
            return try JSONDecoder().decode(TimerPreset.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    /// プリセットを削除する
    func deletePreset(id: Int) async throws {
        guard let url = URL(string: "\(baseURL)/presets/\(id)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    // MARK: - Records API
    
    /// ポモドーロセッション記録を保存する
    func saveRecord(taskName: String, durationMinutes: Int, date: Date = Date()) async throws {
        guard let url = URL(string: "\(baseURL)/records/") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dateString = AppTheme.dateFormatterYYYYMMDD.string(from: date)
        let recordData: [String: Any] = [
            "task_name": taskName,
            "duration_minutes": durationMinutes,
            "date": dateString
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: recordData, options: [])
        } catch {
            throw APIError.encodingError(error)
        }
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    // MARK: - Stats API
    
    /// 今週の統計データを取得する
    func fetchWeeklyStats() async throws -> [DailyStat] {
        guard let url = URL(string: "\(baseURL)/stats/weekly") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        
        do {
            return try JSONDecoder().decode([DailyStat].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    /// 今日のタイムライン記録を取得する
    func fetchTimeline() async throws -> [TimelineRecord] {
        guard let url = URL(string: "\(baseURL)/stats/timeline") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        
        do {
            return try JSONDecoder().decode([TimelineRecord].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - Helper
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}
