import Foundation

// 豆瓣 API 服务
final class DoubanAPIService {
    static let shared = DoubanAPIService()

    private let networkClient = NetworkClient.shared

    private init() {}

    // 获取豆瓣列表
    func getDoubanList(
        type: String,
        tag: String,
        pageStart: Int = 0,
        pageLimit: Int = Constants.doubanPageSize
    ) async throws -> (total: Int, list: [DoubanItem]) {
        let siteConfig = ConfigService.shared.getSiteConfig()
        let host = getDataHost(proxyType: siteConfig.doubanProxyType, customUrl: siteConfig.doubanProxy)

        guard let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(host)/j/search_subjects?type=\(type)&tag=\(encodedTag)&sort=recommend&page_limit=\(pageLimit)&page_start=\(pageStart)") else {
            throw NetworkError.invalidURL
        }

        let headers = [
            "Referer": "https://movie.douban.com/",
            "Accept": "application/json"
        ]

        struct DoubanRawResponse: Decodable {
            let total: Int?
            let subjects: [DoubanRawSubject]?
        }

        struct DoubanRawSubject: Decodable {
            let id: String
            let title: String
            let card_subtitle: String?
            let cover: String
            let rate: String?
        }

        let data: DoubanRawResponse = try await networkClient.get(
            url: url.absoluteString,
            headers: headers,
            timeout: Constants.searchTimeout
        )

        let list: [DoubanItem] = (data.subjects ?? []).map { item in
            DoubanItem(
                id: item.id,
                title: item.title,
                cover: processImageUrl(item.cover),
                rate: item.rate ?? "",
                year: item.card_subtitle?.extractYear ?? ""
            )
        }

        return (total: data.total ?? 0, list: list)
    }

    // 处理图片 URL 代理
    func processImageUrl(_ url: String) -> String {
        guard !url.isEmpty, url.contains("doubanio.com") else { return url }

        let siteConfig = ConfigService.shared.getSiteConfig()

        switch siteConfig.doubanImageProxyType {
        case .tencentCdn:
            return url.replacingOccurrences(of: "img\\d+\\.doubanio\\.com", with: "img.doubanio.cmliussss.net", options: .regularExpression)
        case .aliCdn:
            return url.replacingOccurrences(of: "img\\d+\\.doubanio\\.com", with: "img.doubanio.cmliussss.com", options: .regularExpression)
        case .custom:
            if !siteConfig.doubanImageProxy.isEmpty {
                return "\(siteConfig.doubanImageProxy)\(url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url)"
            }
            return url
        case .direct:
            return url
        }
    }

    // 获取数据源域名
    private func getDataHost(proxyType: DoubanProxyType, customUrl: String) -> String {
        switch proxyType {
        case .tencentCdn:
            return Constants.doubanHosts["cmliussss-cdn-tencent"]!
        case .aliCdn:
            return Constants.doubanHosts["cmliussss-cdn-ali"]!
        case .custom:
            return customUrl.isEmpty ? "https://movie.douban.com" : customUrl
        case .direct:
            return Constants.doubanHosts["direct"]!
        }
    }
}
