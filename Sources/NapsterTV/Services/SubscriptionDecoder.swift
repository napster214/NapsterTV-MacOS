import Foundation

// 订阅配置解码器，支持 JSON / Base58 / Base64 回退
struct SubscriptionDecoder {
    static func decode(_ raw: String) -> String {
        let trimmed = stripBOM(raw).trimmingCharacters(in: .whitespacesAndNewlines)

        // 先尝试直接 JSON
        if isValidJSON(trimmed) { return trimmed }

        // 去除所有空白字符，用于 Base58 / Base64 解码
        let compact = removeAllWhitespace(trimmed)

        // 尝试 Base58 解码
        if let b58 = Base58Decoder.decode(compact) {
            let cleaned = stripBOM(b58).trimmingCharacters(in: .whitespacesAndNewlines)
            if isValidJSON(cleaned) { return cleaned }
            if let inner = decodeBase64(cleaned), isValidJSON(inner) { return inner }
        }

        // 尝试 Base64 解码（标准 + URL-safe）
        if let b64 = decodeBase64(compact), isValidJSON(b64) { return b64 }

        return trimmed
    }

    // MARK: - Helpers

    static func isValidJSON(_ text: String) -> Bool {
        guard let data = text.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    static func decodeBase64(_ string: String) -> String? {
        let cleaned = removeAllWhitespace(string)

        if let result = decodeBase64Standard(cleaned) { return result }

        let standard = cleaned
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        return decodeBase64Standard(standard)
    }

    private static func decodeBase64Standard(_ string: String) -> String? {
        var padded = string
        let remainder = padded.count % 4
        if remainder > 0 {
            padded += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: padded) else { return nil }
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        return stripBOM(text).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func stripBOM(_ string: String) -> String {
        if string.hasPrefix("\u{FEFF}") {
            return String(string.dropFirst())
        }
        return string
    }

    private static func removeAllWhitespace(_ string: String) -> String {
        string.unicodeScalars.filter { !CharacterSet.whitespacesAndNewlines.contains($0) }
            .map { String($0) }
            .joined()
    }
}
