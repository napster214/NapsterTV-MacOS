import Foundation

// 多源并发搜索服务
final class SourceSearchService {
    static let shared = SourceSearchService()

    private let macCMSApi = MacCMSAPIService.shared

    private init() {}

    typealias ProgressHandler = (SearchProgress) -> Void

    func searchAllSourcesSimple(
        query: String,
        onProgress: ProgressHandler? = nil
    ) async -> (results: [SearchResult], failures: [SourceFailure]) {
        let apiSites = ConfigService.shared.getAvailableApiSites()
        if apiSites.isEmpty {
            return (results: [], failures: [])
        }

        let total = apiSites.count
        var completed = 0
        var allResults: [SearchResult] = []
        var failures: [SourceFailure] = []

        func emitProgress() {
            onProgress?(SearchProgress(
                completedSources: completed,
                totalSources: total,
                results: allResults
            ))
        }

        await withTaskGroup(of: SearchResultBatch.self) { group in
            for site in apiSites {
                group.addTask {
                    do {
                        let results = try await self.macCMSApi.searchFromApi(apiSite: site, query: query)
                        return SearchResultBatch(results: results, failure: nil)
                    } catch {
                        return SearchResultBatch(results: [], failure: SourceFailure(
                            key: site.key,
                            name: site.name,
                            message: error.localizedDescription
                        ))
                    }
                }
            }

            for await batch in group {
                completed += 1
                allResults.append(contentsOf: batch.results)
                if let failure = batch.failure {
                    failures.append(failure)
                }
                emitProgress()
            }
        }

        let siteConfig = ConfigService.shared.getSiteConfig()
        let filtered = siteConfig.disableYellowFilter ? allResults : ContentFilter.filterYellowResults(allResults)

        return (results: filtered, failures: failures)
    }
}

// 辅助类型
private struct SearchResultBatch {
    let results: [SearchResult]
    let failure: SourceFailure?
}
