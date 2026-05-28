import Foundation

// 搜索进度
struct SearchProgress {
    let completedSources: Int
    let totalSources: Int
    let results: [SearchResult]

    var progress: Double {
        guard totalSources > 0 else { return 0 }
        return Double(completedSources) / Double(totalSources)
    }
}

// 源搜索失败信息
struct SourceFailure: Identifiable {
    let key: String
    let name: String
    let message: String

    var id: String { key }
}
