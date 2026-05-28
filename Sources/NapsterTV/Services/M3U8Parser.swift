import Foundation

// M3U8 播放列表解析器
struct M3U8Parser {

    // 从 RESOLUTION 标签检测分辨率
    static func parseResolutionToQuality(_ manifest: String) -> String? {
        let lines = manifest.components(separatedBy: "\n")
        var maxWidth = 0

        for line in lines {
            if line.hasPrefix("#EXT-X-STREAM-INF") {
                if let regex = try? NSRegularExpression(pattern: "RESOLUTION=(\\d+)x(\\d+)"),
                   let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                   let range = Range(match.range(at: 1), in: line),
                   let width = Int(line[range]) {
                    maxWidth = max(maxWidth, width)
                }
            }
        }

        if maxWidth == 0 { return nil }
        if maxWidth >= 3840 { return "4K" }
        if maxWidth >= 2560 { return "2K" }
        if maxWidth >= 1920 { return "1080p" }
        if maxWidth >= 1280 { return "720p" }
        if maxWidth >= 854 { return "480p" }
        return "SD"
    }

    // 从 BANDWIDTH 估算分辨率（兜底）
    static func parseBandwidthToQuality(_ manifest: String) -> String {
        var bandwidths: [Int] = []
        if let regex = try? NSRegularExpression(pattern: "BANDWIDTH=(\\d+)") {
            let range = NSRange(manifest.startIndex..., in: manifest)
            let matches = regex.matches(in: manifest, options: [], range: range)
            for match in matches {
                if let range = Range(match.range(at: 1), in: manifest),
                   let bandwidth = Int(manifest[range]) {
                    bandwidths.append(bandwidth)
                }
            }
        }

        guard let maxBandwidth = bandwidths.max() else { return "未知" }

        if maxBandwidth >= 15_000_000 { return "4K" }
        if maxBandwidth >= 8_000_000 { return "2K" }
        if maxBandwidth >= 4_000_000 { return "1080p" }
        if maxBandwidth >= 2_000_000 { return "720p" }
        if maxBandwidth >= 800_000 { return "480p" }
        return "SD"
    }

    // 找到首个 TS 分片 URL
    static func findFirstSegmentUrl(manifest: String, m3u8Url: String) -> String? {
        let lines = manifest.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }

        if manifest.contains("#EXT-X-STREAM-INF") {
            for i in 0..<(lines.count - 1) {
                if lines[i].hasPrefix("#EXT-X-STREAM-INF") {
                    let nextLine = lines[i + 1]
                    if !nextLine.isEmpty && !nextLine.hasPrefix("#") {
                        return resolveUrl(nextLine, baseUrl: m3u8Url)
                    }
                }
            }
            return nil
        }

        for line in lines {
            if !line.isEmpty && !line.hasPrefix("#") && (line.hasSuffix(".ts") || line.contains(".ts?")) {
                return resolveUrl(line, baseUrl: m3u8Url)
            }
        }

        return nil
    }

    // 解析相对 URL
    private static func resolveUrl(_ uri: String, baseUrl: String) -> String? {
        if uri.hasPrefix("http://") || uri.hasPrefix("https://") { return uri }
        if uri.contains("..") { return nil }
        guard let lastSlash = baseUrl.lastIndex(of: "/") else { return nil }
        let base = String(baseUrl[...lastSlash])
        return base + uri
    }
}
