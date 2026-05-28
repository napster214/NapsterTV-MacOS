import Foundation

// 苹果CMS API 搜索条目（容错解析，支持 String/Int 类型自动转换）
struct ApiSearchItem: Codable {
    let vodId: String
    let vodName: String
    let vodPic: String
    let vodRemarks: String?
    let vodPlayUrl: String?
    let vodClass: String?
    let vodYear: String?
    let vodContent: String?
    let vodDoubanId: Int?
    let typeName: String?

    enum CodingKeys: String, CodingKey {
        case vodId = "vod_id"
        case vodName = "vod_name"
        case vodPic = "vod_pic"
        case vodRemarks = "vod_remarks"
        case vodPlayUrl = "vod_play_url"
        case vodClass = "vod_class"
        case vodYear = "vod_year"
        case vodContent = "vod_content"
        case vodDoubanId = "vod_douban_id"
        case typeName = "type_name"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // vodId 兼容 Int 和 String
        vodId = try Self.decodeStringOrInt(container: container, key: .vodId, default: "")

        // vodName 兼容 String，失败给空串
        vodName = (try? container.decode(String.self, forKey: .vodName)) ?? ""

        // vodPic 兼容 String
        vodPic = (try? container.decode(String.self, forKey: .vodPic)) ?? ""

        vodRemarks = try? container.decode(String.self, forKey: .vodRemarks)
        vodPlayUrl = try? container.decode(String.self, forKey: .vodPlayUrl)
        vodClass = try? container.decode(String.self, forKey: .vodClass)
        vodContent = try? container.decode(String.self, forKey: .vodContent)
        typeName = try? container.decode(String.self, forKey: .typeName)

        // vodYear 兼容 Int 和 String
        vodYear = try? Self.decodeStringOrInt(container: container, key: .vodYear)

        // vodDoubanId 兼容 Int 和 String
        vodDoubanId = try? Self.decodeIntOrString(container: container, key: .vodDoubanId)
    }

    /// 字段可能是 String 或 Int，统一返回 String
    private static func decodeStringOrInt(container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys, default: String = "") throws -> String {
        if let str = try? container.decode(String.self, forKey: key) {
            return str
        }
        if let int = try? container.decode(Int.self, forKey: key) {
            return String(int)
        }
        return `default`
    }

    /// 字段可能是 Int 或 String，统一返回 Int
    private static func decodeIntOrString(container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> Int? {
        if let int = try? container.decode(Int.self, forKey: key) {
            return int
        }
        if let str = try? container.decode(String.self, forKey: key),
           let int = Int(str.trimmingCharacters(in: .whitespaces)) {
            return int
        }
        return nil
    }
}

// 苹果CMS API 搜索响应
struct MacCMSResponse: Codable {
    let list: [ApiSearchItem]?
    var pagecount: Int?
    var total: Int?

    enum CodingKeys: String, CodingKey {
        case list
        case pagecount
        case total
    }

    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<MacCMSResponse.CodingKeys>
        // 有些 API 返回 code/msg/data 包裹结构，先尝试直接解析
        do {
            container = try decoder.container(keyedBy: CodingKeys.self)
        } catch {
            // 如果直接解析失败，尝试从 "data" 字段下解析
            let wrapper = try decoder.container(keyedBy: WrapperKeys.self)
            if let dataContainer = try? wrapper.nestedContainer(keyedBy: CodingKeys.self, forKey: .data) {
                container = dataContainer
            } else {
                throw error
            }
        }

        list = try? container.decode([ApiSearchItem].self, forKey: .list)
        pagecount = try? container.decode(Int.self, forKey: .pagecount)
        total = try? container.decode(Int.self, forKey: .total)

        // pagecount 也可能是 String
        if pagecount == nil, let str = try? container.decode(String.self, forKey: .pagecount) {
            pagecount = Int(str)
        }
        if total == nil, let str = try? container.decode(String.self, forKey: .total) {
            total = Int(str)
        }
    }

    private enum WrapperKeys: String, CodingKey {
        case code, msg, data
    }
}
