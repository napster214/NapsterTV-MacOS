import Foundation

// 源测试结果
struct SourceTestResult {
    let quality: String        // "4K", "1080p", "720p" 等
    let loadSpeed: String      // "1.5 MB/s", "500 KB/s", "未知"
    let pingTime: TimeInterval // 毫秒
}

// 评分后的源
struct ScoredSource: Identifiable {
    let source: SearchResult
    let testResult: SourceTestResult
    let score: Int             // 0-100

    var id: String { "\(source.source)_\(source.id)" }
}
