import Foundation

// 视频源配置
struct SourceConfig: Codable, Identifiable {
    let key: String
    let name: String
    let api: String
    let detail: String?
    let from: SourceFrom
    var disabled: Bool

    var id: String { key }

    enum SourceFrom: String, Codable {
        case config
        case custom
    }
}

// API 站点（搜索/详情时使用）
struct ApiSite: Codable {
    let key: String
    let api: String
    let name: String
    let detail: String?
}
