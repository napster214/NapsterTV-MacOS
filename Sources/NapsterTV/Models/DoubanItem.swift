import Foundation

// 豆瓣影视条目
struct DoubanItem: Identifiable, Codable {
    let id: String
    let title: String
    let cover: String
    let rate: String
    let year: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case cover
        case rate
        case year
    }
}

// 豆瓣列表 API 响应
struct DoubanListResponse: Codable {
    let subjects: [DoubanItem]
    let total: Int?
    let start: Int?
}
