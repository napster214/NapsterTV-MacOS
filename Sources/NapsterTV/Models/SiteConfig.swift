import Foundation

enum DoubanProxyType: String, Codable, CaseIterable {
    case tencentCdn = "cmliussss-cdn-tencent"
    case aliCdn = "cmliussss-cdn-ali"
    case direct = "direct"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .tencentCdn: return "cmliussss 腾讯云"
        case .aliCdn: return "cmliussss 阿里云"
        case .direct: return "直连"
        case .custom: return "自定义"
        }
    }
}

// 站点配置
struct SiteConfig: Codable {
    var siteName: String
    var announcement: String
    var searchDownstreamMaxPage: Int
    var siteInterfaceCacheTime: Int
    var disableYellowFilter: Bool
    var fluidSearch: Bool
    var doubanProxyType: DoubanProxyType
    var doubanProxy: String
    var doubanImageProxyType: DoubanProxyType
    var doubanImageProxy: String

    enum CodingKeys: String, CodingKey {
        case siteName = "SiteName"
        case announcement = "Announcement"
        case searchDownstreamMaxPage = "SearchDownstreamMaxPage"
        case siteInterfaceCacheTime = "SiteInterfaceCacheTime"
        case disableYellowFilter = "DisableYellowFilter"
        case fluidSearch = "FluidSearch"
        case doubanProxyType = "DoubanProxyType"
        case doubanProxy = "DoubanProxy"
        case doubanImageProxyType = "DoubanImageProxyType"
        case doubanImageProxy = "DoubanImageProxy"
    }

    static var `default`: SiteConfig {
        SiteConfig(
            siteName: "NapsterTV",
            announcement: "",
            searchDownstreamMaxPage: 5,
            siteInterfaceCacheTime: 7200,
            disableYellowFilter: false,
            fluidSearch: false,
            doubanProxyType: .tencentCdn,
            doubanProxy: "",
            doubanImageProxyType: .tencentCdn,
            doubanImageProxy: ""
        )
    }
}
