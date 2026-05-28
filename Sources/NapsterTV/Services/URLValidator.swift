import Foundation

// URL 安全校验，拦截私有 IP 地址
struct URLValidator {
    private static let privateHostPattern: NSRegularExpression? = {
        try? NSRegularExpression(
            pattern: "^(127\\.\\d+\\.\\d+\\.\\d+|10\\.\\d+\\.\\d+\\.\\d+|172\\.(1[6-9]|2\\d|3[01])\\.\\d+\\.\\d+|192\\.168\\.\\d+\\.\\d+|0\\.0\\.0\\.0|localhost)$",
            options: .caseInsensitive
        )
    }()

    private static let hostExtractPattern: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "^https?://([^/:]+)", options: .caseInsensitive)
    }()

    struct ValidationResult {
        let valid: Bool
        let reason: String?
    }

    static func isSafeHttpUrl(_ urlString: String) -> ValidationResult {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmed.hasPrefix("http://") && !trimmed.hasPrefix("https://") {
            return ValidationResult(valid: false, reason: "地址必须以 http:// 或 https:// 开头")
        }

        guard let hostExtract = hostExtractPattern,
              let match = hostExtract.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let range = Range(match.range(at: 1), in: trimmed) else {
            return ValidationResult(valid: false, reason: "地址格式不正确")
        }

        let host = String(trimmed[range])

        if let privatePattern = privateHostPattern,
           privatePattern.firstMatch(in: host, range: NSRange(host.startIndex..., in: host)) != nil {
            return ValidationResult(valid: false, reason: "不允许使用内网地址")
        }

        return ValidationResult(valid: true, reason: nil)
    }
}
