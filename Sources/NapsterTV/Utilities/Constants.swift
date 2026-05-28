import Foundation

enum Constants {
    // 网络超时
    static let defaultTimeout: TimeInterval = 20
    static let searchTimeout: TimeInterval = 15
    static let preferTimeout: TimeInterval = 4

    // 搜索
    static let maxSearchHistory = 20
    static let searchCacheMaxEntries = 500
    static let searchCacheMaxTTL: TimeInterval = 900       // 15 分钟
    static let defaultCacheTTL: TimeInterval = 7200        // 2 小时

    // 播放器
    static let progressSaveInterval: TimeInterval = 5
    static let playbackSpeeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    static let sourcePreferenceTimeout: TimeInterval = 30

    // 海报固定尺寸
    static let posterWidth: CGFloat = 150
    static let posterHeight: CGFloat = 225  // 150 * 1.5

    // 豆瓣
    static let doubanPageSize = 20
    static let doubanHosts: [String: String] = [
        "cmliussss-cdn-tencent": "https://movie.douban.cmliussss.net",
        "cmliussss-cdn-ali": "https://movie.douban.cmliussss.com",
        "direct": "https://movie.douban.com"
    ]
    static let movieTags = ["热门", "最新", "经典", "豆瓣高分", "华语", "欧美", "韩国", "日本", "动作", "喜剧", "爱情", "科幻", "悬疑", "恐怖", "治愈"]
    static let tvTags = ["热门", "美剧", "英剧", "韩剧", "日剧", "国产剧", "港剧", "日本动画", "综艺", "纪录片"]

    // 源偏好评分
    static let preferenceConcurrency = 4
    static let preferenceQualityWeight = 0.4
    static let preferenceSpeedWeight = 0.4
    static let preferenceLatencyWeight = 0.2
    static let preferenceBetterThreshold = 15

    // 存储键名
    static let storagePlayRecords = "orangetv_play_records"
    static let storageFavorites = "orangetv_favorites"
    static let storageSearchHistory = "orangetv_search_history"
    static let storageSkipConfigs = "orangetv_skip_configs"
    static let storageAdminConfig = "orangetv_admin_config"

    // 分类快捷链接
    static let categoryLinks: [(title: String, tag: String, type: String)] = [
        ("动作", "动作", "movie"),
        ("喜剧", "喜剧", "movie"),
        ("科幻", "科幻", "movie"),
        ("美剧", "美剧", "tv"),
        ("韩剧", "韩剧", "tv"),
        ("日剧", "日剧", "tv")
    ]

    // Tab 定义
    enum Tab: Int, CaseIterable {
        case home = 0
        case movie = 1
        case tv = 2
        case search = 3
        case favorites = 4
        case history = 5
        case settings = 6

        var title: String {
            switch self {
            case .home: return "首页"
            case .movie: return "电影"
            case .tv: return "剧集"
            case .search: return "搜索"
            case .favorites: return "收藏"
            case .history: return "记录"
            case .settings: return "设置"
            }
        }

        var iconName: String {
            switch self {
            case .home: return "house"
            case .movie: return "film"
            case .tv: return "tv"
            case .search: return "magnifyingglass"
            case .favorites: return "heart"
            case .history: return "clock"
            case .settings: return "gearshape"
            }
        }
    }
}
