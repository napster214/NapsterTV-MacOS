import Foundation

// 播放记录
struct PlayRecord: Codable {
    let title: String
    let sourceName: String
    let cover: String
    let year: String
    let index: Int
    let totalEpisodes: Int
    let playTime: Double
    let totalTime: Double
    let saveTime: Double
    let searchTitle: String

    enum CodingKeys: String, CodingKey {
        case title
        case sourceName = "source_name"
        case cover
        case year
        case index
        case totalEpisodes = "total_episodes"
        case playTime = "play_time"
        case totalTime = "total_time"
        case saveTime = "save_time"
        case searchTitle = "search_title"
    }
}
