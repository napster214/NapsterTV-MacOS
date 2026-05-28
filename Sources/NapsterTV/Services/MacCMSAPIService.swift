import Foundation

// 苹果CMS API 服务
final class MacCMSAPIService {
    static let shared = MacCMSAPIService()

    private let networkClient = NetworkClient.shared
    private let searchCache = LRUCache<String, TimedCacheEntry<[SearchResult]>>(maxSize: Constants.searchCacheMaxEntries)

    private init() {}

    // MARK: - 搜索

    func searchFromApi(apiSite: ApiSite, query: String) async throws -> [SearchResult] {
        let cacheKey = "\(apiSite.key)::\(query.trimmingCharacters(in: .whitespaces))::1"

        if let cached = searchCache.get(cacheKey), !cached.isExpired {
            return cached.data
        }

        let directApi = stripProxy(apiSite.api)
        let apiUrl = "\(directApi)?ac=videolist&wd=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"

        let data: MacCMSResponse = try await networkClient.get(url: apiUrl, timeout: Constants.searchTimeout)

        guard let list = data.list, !list.isEmpty else { return [] }

        let results = parseSearchResults(list, apiSite)

        let ttl = min(Double(ConfigService.shared.getCacheTime()), Constants.searchCacheMaxTTL)
        searchCache.set(cacheKey, value: TimedCacheEntry(
            expiresAt: Date().addingTimeInterval(ttl),
            data: results
        ))

        return results
    }

    // MARK: - 详情

    func getDetailFromApi(apiSite: ApiSite, id: String) async throws -> SearchResult {
        if apiSite.detail != nil {
            return try await handleSpecialSourceDetail(id: id, apiSite: apiSite)
        }

        let directApi = stripProxy(apiSite.api)
        let detailUrl = "\(directApi)?ac=videolist&ids=\(id)"

        let data: MacCMSResponse = try await networkClient.get(url: detailUrl)

        guard let list = data.list, let first = list.first else {
            throw NetworkError.networkError("获取到的详情内容无效")
        }

        return try parseSingleDetail(first, apiSite: apiSite, id: id)
    }

    // MARK: - 获取视频详情（带 fallback）

    func fetchVideoDetail(source: String, id: String, fallbackTitle: String?) async throws -> SearchResult {
        guard let apiSite = ConfigService.shared.getAvailableApiSites().first(where: { $0.key == source }) else {
            throw NetworkError.networkError("无效的API来源")
        }

        if let title = fallbackTitle {
            do {
                let searchData = try await searchFromApi(apiSite: apiSite, query: title.trimmingCharacters(in: .whitespaces))
                if let exactMatch = searchData.first(where: { $0.source == source && $0.id == id }) {
                    return exactMatch
                }
            } catch {
                // fallback to detail API
            }
        }

        return try await getDetailFromApi(apiSite: apiSite, id: id)
    }

    // MARK: - 解析

    private func parseSearchResults(_ items: [ApiSearchItem], _ apiSite: ApiSite) -> [SearchResult] {
        items.compactMap { item in
            let (episodes, titles) = parsePlayUrl(item.vodPlayUrl)
            guard !episodes.isEmpty else { return nil }

            return SearchResult(
                id: item.vodId,
                title: item.vodName.trimmingCharacters(in: .whitespacesAndNewlines),
                poster: item.vodPic,
                episodes: episodes,
                episodesTitles: titles,
                source: apiSite.key,
                sourceName: apiSite.name,
                className: item.vodClass,
                tag: nil,
                year: item.vodYear?.extractYear.isEmpty == false ? item.vodYear!.extractYear : "unknown",
                desc: HTMLCleaner.clean(item.vodContent ?? ""),
                typeName: item.typeName,
                doubanId: item.vodDoubanId
            )
        }
    }

    private func parseSingleDetail(_ item: ApiSearchItem, apiSite: ApiSite, id: String) throws -> SearchResult {
        let (episodes, titles) = parsePlayUrl(item.vodPlayUrl)

        return SearchResult(
            id: id,
            title: item.vodName,
            poster: item.vodPic,
            episodes: episodes,
            episodesTitles: titles,
            source: apiSite.key,
            sourceName: apiSite.name,
            className: item.vodClass,
            tag: nil,
            year: item.vodYear?.extractYear.isEmpty == false ? item.vodYear!.extractYear : "unknown",
            desc: HTMLCleaner.clean(item.vodContent ?? ""),
            typeName: item.typeName,
            doubanId: item.vodDoubanId
        )
    }

    // 解析 vod_play_url 格式: "title1$url1#title2$url2$$$title3$url3#title4$url4"
    func parsePlayUrl(_ playUrl: String?) -> (episodes: [String], titles: [String]) {
        guard let playUrl = playUrl, !playUrl.isEmpty else { return ([], []) }

        let urlArrays = playUrl.components(separatedBy: "$$$")
        var bestEpisodes: [String] = []
        var bestTitles: [String] = []

        for urlArray in urlArrays {
            var episodes: [String] = []
            var titles: [String] = []

            let titleUrlArray = urlArray.components(separatedBy: "#")
            for titleUrl in titleUrlArray {
                let parts = titleUrl.components(separatedBy: "$")
                if parts.count == 2, parts[1].hasSuffix(".m3u8") {
                    titles.append(parts[0])
                    episodes.append(parts[1])
                }
            }

            if episodes.count > bestEpisodes.count {
                bestEpisodes = episodes
                bestTitles = titles
            }
        }

        return (bestEpisodes, bestTitles)
    }

    // MARK: - 特殊源 HTML 抓取

    private func handleSpecialSourceDetail(id: String, apiSite: ApiSite) async throws -> SearchResult {
        let directDetail = stripProxy(apiSite.detail ?? apiSite.api)
        let detailUrl = "\(directDetail)/index.php/vod/detail/id/\(id).html"

        let html = try await networkClient.getText(url: detailUrl, headers: ["Accept": "text/html"])

        var matches: [String] = []
        let m3u8Pattern = "\\$(https?://[^\"'\\s]+?\\.m3u8)"
        if let regex = try? NSRegularExpression(pattern: m3u8Pattern, options: []) {
            let range = NSRange(html.startIndex..., in: html)
            let results = regex.matches(in: html, options: [], range: range)
            for match in results {
                if let range = Range(match.range(at: 1), in: html) {
                    var link = String(html[range])
                    if let parenIndex = link.firstIndex(of: "("), parenIndex > link.startIndex {
                        link = String(link[..<parenIndex])
                    }
                    if !matches.contains(link) {
                        matches.append(link)
                    }
                }
            }
        }

        let episodesTitles = matches.indices.map { "\($0 + 1)" }

        var title = ""
        if let regex = try? NSRegularExpression(pattern: "<h1[^>]*>([^<]+)</h1>", options: []),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            title = String(html[range]).trimmingCharacters(in: .whitespaces)
        }

        var desc = ""
        if let regex = try? NSRegularExpression(pattern: "<div[^>]*class=[\"']sketch[\"'][^>]*>([\\s\\S]*?)</div>", options: []),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            desc = HTMLCleaner.clean(String(html[range]))
        }

        var cover = ""
        if let regex = try? NSRegularExpression(pattern: "(https?://[^\"'\\s]+?\\.jpg)", options: []),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            cover = String(html[range]).trimmingCharacters(in: .whitespaces)
        }

        var year = "unknown"
        if let regex = try? NSRegularExpression(pattern: ">(\\d{4})<", options: []),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            year = String(html[range])
        }

        return SearchResult(
            id: id, title: title, poster: cover,
            episodes: matches, episodesTitles: episodesTitles,
            source: apiSite.key, sourceName: apiSite.name,
            className: "", tag: nil, year: year,
            desc: desc, typeName: "", doubanId: nil
        )
    }

    // 去除 CORS 代理前缀
    private func stripProxy(_ apiUrl: String) -> String {
        if let regex = try? NSRegularExpression(pattern: "^[^?]+/\\?url=(https?://.+)$", options: [.caseInsensitive]),
           let match = regex.firstMatch(in: apiUrl, range: NSRange(apiUrl.startIndex..., in: apiUrl)),
           let range = Range(match.range(at: 1), in: apiUrl) {
            return String(apiUrl[range])
        }
        if let regex = try? NSRegularExpression(pattern: "^[^?]+[?&]url=(https?://.+)$", options: [.caseInsensitive]),
           let match = regex.firstMatch(in: apiUrl, range: NSRange(apiUrl.startIndex..., in: apiUrl)),
           let range = Range(match.range(at: 1), in: apiUrl) {
            return String(apiUrl[range])
        }
        return apiUrl
    }
}
