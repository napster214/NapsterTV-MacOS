import Foundation

// 搜索结果
struct SearchResult: Identifiable, Codable {
    let id: String
    let title: String
    let poster: String
    let episodes: [String]
    let episodesTitles: [String]
    let source: String
    let sourceName: String
    let className: String?
    let tag: String?
    let year: String
    let desc: String?
    let typeName: String?
    let doubanId: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case poster
        case episodes
        case episodesTitles = "episodes_titles"
        case source
        case sourceName = "source_name"
        case className = "class"
        case tag
        case year
        case desc
        case typeName = "type_name"
        case doubanId = "douban_id"
    }
}
