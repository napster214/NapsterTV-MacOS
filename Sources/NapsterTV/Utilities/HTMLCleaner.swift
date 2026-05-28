import Foundation

// HTML 标签清理工具
struct HTMLCleaner {
    private static let tagPattern: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "<[^>]+>", options: [])
    }()

    private static let whitespacePattern: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "[ \t]+", options: [])
    }()

    static func clean(_ text: String) -> String {
        guard let regex = tagPattern else { return text }
        let range = NSRange(text.startIndex..., in: text)
        var result = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "\n")
        // 压缩连续换行
        result = result.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        // 压缩水平空白
        if let wsRegex = whitespacePattern {
            let wsRange = NSRange(result.startIndex..., in: result)
            result = wsRegex.stringByReplacingMatches(in: result, options: [], range: wsRange, withTemplate: " ")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
