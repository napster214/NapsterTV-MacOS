import Foundation

// 网络错误类型
enum NetworkError: LocalizedError {
    case invalidURL
    case timeout
    case httpError(statusCode: Int)
    case networkError(String)
    case privateIPBlocked

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 URL"
        case .timeout: return "请求超时"
        case .httpError(let code): return "HTTP 错误: \(code)"
        case .networkError(let msg): return msg
        case .privateIPBlocked: return "不允许使用内网地址"
        }
    }
}

// 通用网络客户端
final class NetworkClient {
    static let shared = NetworkClient()

    private let session: URLSession
    private let defaultHeaders: [String: String] = [
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
        "Accept": "application/json"
    ]

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.defaultTimeout
        self.session = URLSession(configuration: config)
    }

    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()

    func get<T: Decodable>(
        url: String,
        headers: [String: String]? = nil,
        timeout: TimeInterval = Constants.defaultTimeout
    ) async throws -> T {
        guard let request = buildRequest(url: url, method: "GET", headers: headers, timeout: timeout) else {
            throw NetworkError.invalidURL
        }
        let (data, response) = try await execute(request: request)
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            if let jsonString = String(data: data, encoding: .utf8),
               let jsonData = jsonString.data(using: .utf8) {
                return try jsonDecoder.decode(T.self, from: jsonData)
            }
            if let raw = String(data: data, encoding: .utf8) {
                print("[NetworkClient] JSON解析失败, 原始响应前300字符: \(raw.prefix(300))")
            }
            throw error
        }
    }

    func getText(
        url: String,
        headers: [String: String]? = nil,
        timeout: TimeInterval = Constants.defaultTimeout
    ) async throws -> String {
        var mergedHeaders = defaultHeaders
        mergedHeaders["Accept"] = "text/plain, */*"
        mergedHeaders.merge(headers ?? [:]) { _, new in new }

        guard let request = buildRequest(url: url, method: "GET", headers: mergedHeaders, timeout: timeout) else {
            throw NetworkError.invalidURL
        }
        let (data, _) = try await execute(request: request)
        return String(data: data, encoding: .utf8) ?? ""
    }

    func getData(
        url: String,
        headers: [String: String]? = nil,
        timeout: TimeInterval = Constants.defaultTimeout
    ) async throws -> Data {
        var mergedHeaders = defaultHeaders
        mergedHeaders["Accept"] = "*/*"
        mergedHeaders.merge(headers ?? [:]) { _, new in new }

        guard let request = buildRequest(url: url, method: "GET", headers: mergedHeaders, timeout: timeout) else {
            throw NetworkError.invalidURL
        }
        let (data, _) = try await execute(request: request)
        return data
    }

    func getRaw(
        url: String,
        headers: [String: String]? = nil,
        timeout: TimeInterval = Constants.defaultTimeout
    ) async throws -> (Data, HTTPURLResponse) {
        guard let request = buildRequest(url: url, method: "GET", headers: headers, timeout: timeout) else {
            throw NetworkError.invalidURL
        }
        let (data, response) = try await execute(request: request)
        return (data, response)
    }

    // MARK: - Private

    private func buildRequest(
        url: String,
        method: String,
        headers: [String: String]?,
        timeout: TimeInterval
    ) -> URLRequest? {
        guard let urlObj = URL(string: url) else { return nil }

        var request = URLRequest(url: urlObj)
        request.httpMethod = method
        request.timeoutInterval = timeout

        var mergedHeaders = defaultHeaders
        mergedHeaders.merge(headers ?? [:]) { _, new in new }
        for (key, value) in mergedHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    private func execute(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.networkError("无效响应")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpError(statusCode: httpResponse.statusCode)
            }

            return (data, httpResponse)
        } catch let error as NetworkError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw NetworkError.timeout
            }
            throw NetworkError.networkError(error.localizedDescription)
        }
    }
}
