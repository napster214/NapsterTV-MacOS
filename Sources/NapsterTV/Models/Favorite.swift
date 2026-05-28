import Foundation

// 收藏
struct Favorite: Codable {
    let sourceName: String
    let totalEpisodes: Int
    let title: String
    let year: String
    let cover: String
    let saveTime: Double
    let searchTitle: String

    enum CodingKeys: String, CodingKey {
        case sourceName = "source_name"
        case totalEpisodes = "total_episodes"
        case title
        case year
        case cover
        case saveTime = "save_time"
        case searchTitle = "search_title"
    }
}
