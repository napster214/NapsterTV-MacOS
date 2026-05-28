import Foundation

// 精简版管理员配置（单人本地应用）
struct AdminConfig: Codable {
    var configFile: String
    var configSubscription: ConfigSubscription
    var siteConfig: SiteConfig
    var sourceConfig: [SourceConfig]

    enum CodingKeys: String, CodingKey {
        case configFile = "ConfigFile"
        case configSubscription = "ConfigSubscription"
        case siteConfig = "SiteConfig"
        case sourceConfig = "SourceConfig"
    }

    struct ConfigSubscription: Codable {
        var url: String
        var autoUpdate: Bool
        var lastCheck: String

        enum CodingKeys: String, CodingKey {
            case url = "URL"
            case autoUpdate = "AutoUpdate"
            case lastCheck = "LastCheck"
        }
    }

    static var `default`: AdminConfig {
        AdminConfig(
            configFile: "",
            configSubscription: ConfigSubscription(url: "", autoUpdate: false, lastCheck: ""),
            siteConfig: .default,
            sourceConfig: []
        )
    }
}
