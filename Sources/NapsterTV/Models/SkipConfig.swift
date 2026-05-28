import Foundation

// 跳过片头片尾配置
struct SkipConfig: Codable {
    let enable: Bool
    let introTime: Double
    let outroTime: Double

    enum CodingKeys: String, CodingKey {
        case enable
        case introTime = "intro_time"
        case outroTime = "outro_time"
    }
}
