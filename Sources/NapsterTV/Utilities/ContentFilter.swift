import Foundation

// 黄色内容过滤
struct ContentFilter {
    private static let yellowWords = [
        "伦理片", "福利", "里番动漫", "门事件", "萝莉少女",
        "制服诱惑", "国产传媒", "黑丝诱惑", "无码", "日本无码",
        "有码", "日本有码", "SWAG", "网红主播", "色情片",
        "同性片", "福利视频", "福利片", "写真热舞", "倫理片",
        "理论片", "韩国伦理", "港台三级", "日本伦理"
    ]

    static func isYellowContent(title: String, className: String?) -> Bool {
        let text = "\(title) \(className ?? "")".lowercased()
        return yellowWords.contains { text.contains($0.lowercased()) }
    }

    static func filterYellowResults(_ results: [SearchResult]) -> [SearchResult] {
        results.filter { !isYellowContent(title: $0.title, className: $0.className) }
    }
}
