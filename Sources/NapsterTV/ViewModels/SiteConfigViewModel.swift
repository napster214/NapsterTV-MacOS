import Foundation

final class SiteConfigViewModel: ObservableObject {
    @Published var siteConfig: SiteConfig = .default

    func loadConfig() {
        siteConfig = ConfigService.shared.getSiteConfig()
    }

    func saveConfig() {
        ConfigService.shared.updateSiteConfig(siteConfig)
        ConfigService.shared.clearCache()
    }
}
