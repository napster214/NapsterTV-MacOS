import Foundation

// 导航路由
enum Route: Hashable {
    case play(source: String, id: String, title: String, year: String,
              searchTitle: String, prefer: Bool, episodeIndex: Int = 0)
    case config
    case site
    case sources
}
