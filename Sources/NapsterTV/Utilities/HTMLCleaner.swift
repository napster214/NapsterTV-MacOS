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
        // 解码 HTML 实体
        result = decodeHTMLEntities(result)
        // 压缩连续换行
        result = result.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        // 压缩水平空白
        if let wsRegex = whitespacePattern {
            let wsRange = NSRange(result.startIndex..., in: result)
            result = wsRegex.stringByReplacingMatches(in: result, options: [], range: wsRange, withTemplate: " ")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func decodeHTMLEntities(_ text: String) -> String {
        var result = text
        let entities: [String: String] = [
            "&nbsp;": " ", "&lt;": "<", "&gt;": ">",
            "&amp;": "&", "&quot;": "\"", "&apos;": "'",
            "&#39;": "'", "&mdash;": "—", "&ndash;": "–",
            "&hellip;": "…", "&laquo;": "«", "&raquo;": "»"
        ]
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        // 处理 &#数字; 形式的实体
        if let numericRegex = try? NSRegularExpression(pattern: "&#(\\d+);", options: []) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = numericRegex.matches(in: result, options: [], range: range).reversed()
            for match in matches {
                if let numRange = Range(match.range(at: 1), in: result),
                   let code = UInt32(result[numRange]),
                   let scalar = Unicode.Scalar(code) {
                    let fullRange = Range(match.range, in: result)!
                    result.replaceSubrange(fullRange, with: String(scalar))
                }
            }
        }
        return result
    }
}
