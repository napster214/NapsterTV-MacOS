import Foundation

// 配置文件结构
struct ConfigFileStruct: Codable {
    let cacheTime: Int?
    let apiSite: [String: ConfigFileApiSite]?

    enum CodingKeys: String, CodingKey {
        case cacheTime = "cache_time"
        case apiSite = "api_site"
    }
}

struct ConfigFileApiSite: Codable {
    let api: String
    let name: String
    let detail: String?
}

// 配置管理服务
final class ConfigService {
    static let shared = ConfigService()

    private var cachedConfig: AdminConfig?

    private init() {}

    func getConfig() -> AdminConfig {
        if let cached = cachedConfig { return cached }

        var config = PersistenceService.shared.getAdminConfig() ?? .default
        config = refineConfig(config)
        cachedConfig = config
        return config
    }

    func saveConfig(_ config: AdminConfig) {
        cachedConfig = config
        PersistenceService.shared.setAdminConfig(config)
    }

    func clearCache() {
        cachedConfig = nil
    }

    func getAvailableApiSites() -> [ApiSite] {
        getConfig().sourceConfig
            .filter { !$0.disabled }
            .map { ApiSite(key: $0.key, api: $0.api, name: $0.name, detail: $0.detail) }
    }

    func getSiteConfig() -> SiteConfig {
        getConfig().siteConfig
    }

    func getCacheTime() -> Int {
        getConfig().siteConfig.siteInterfaceCacheTime
    }

    func updateSourceConfig(_ sources: [SourceConfig]) {
        var config = getConfig()
        config.sourceConfig = sources
        saveConfig(config)
    }

    func updateSiteConfig(_ siteConfig: SiteConfig) {
        var config = getConfig()
        config.siteConfig = siteConfig
        saveConfig(config)
    }

    func updateConfigFile(_ configFile: String, subscription: AdminConfig.ConfigSubscription? = nil) {
        var config = getConfig()
        config.configFile = configFile
        if let subscription = subscription {
            config.configSubscription = subscription
        }
        saveConfig(config)
    }

    // MARK: - Private

    private func refineConfig(_ config: AdminConfig) -> AdminConfig {
        var config = config

        if config.configFile.isEmpty == false {
            if let data = config.configFile.data(using: .utf8),
               let fileConfig = try? JSONDecoder().decode(ConfigFileStruct.self, from: data) {

                if let apiSite = fileConfig.apiSite {
                    let existingUrls = Set(config.sourceConfig.map { $0.api.lowercased().trimmingCharacters(in: .whitespaces) })

                    for (key, site) in apiSite {
                        guard !site.api.isEmpty, !site.name.isEmpty,
                              site.api.hasPrefix("http://") || site.api.hasPrefix("https://") else { continue }

                        let normalizedUrl = site.api.lowercased().trimmingCharacters(in: .whitespaces)

                        if let existingIndex = config.sourceConfig.firstIndex(where: { $0.key == key }) {
                            // 更新已有源
                            let old = config.sourceConfig[existingIndex]
                            config.sourceConfig[existingIndex] = SourceConfig(
                                key: key, name: site.name, api: site.api,
                                detail: site.detail, from: .config, disabled: old.disabled
                            )
                        } else if !existingUrls.contains(normalizedUrl) {
                            // 新增源
                            config.sourceConfig.append(SourceConfig(
                                key: key, name: site.name, api: site.api,
                                detail: site.detail, from: .config, disabled: false
                            ))
                        }
                    }

                    // 标记不在配置文件中的源为 custom
                    let fileKeys = Set(apiSite.keys)
                    for i in config.sourceConfig.indices {
                        if !fileKeys.contains(config.sourceConfig[i].key) && config.sourceConfig[i].from == .config {
                            config.sourceConfig[i] = SourceConfig(
                                key: config.sourceConfig[i].key,
                                name: config.sourceConfig[i].name,
                                api: config.sourceConfig[i].api,
                                detail: config.sourceConfig[i].detail,
                                from: .custom,
                                disabled: config.sourceConfig[i].disabled
                            )
                        }
                    }
                }

                if let cacheTime = fileConfig.cacheTime, cacheTime > 0 {
                    config.siteConfig.siteInterfaceCacheTime = cacheTime
                }
            }
        }

        // 去重
        var seen = Set<String>()
        config.sourceConfig = config.sourceConfig.filter { seen.insert($0.key).inserted }

        return config
    }
}
