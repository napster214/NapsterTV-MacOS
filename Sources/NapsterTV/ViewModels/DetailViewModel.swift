import Foundation

@MainActor
final class DetailViewModel: ObservableObject {
    @Published var detail: SearchResult?
    @Published var isLoading = false
    @Published var isFavorited = false
    @Published var allSources: [SearchResult] = []

    private var currentSource = ""
    private var currentId = ""

    func loadDetail(source: String, id: String) {
        currentSource = source
        currentId = id
        isLoading = true

        isFavorited = PersistenceService.shared.isFavorited(source: source, id: id)

        Task {
            do {
                let result = try await MacCMSAPIService.shared.fetchVideoDetail(
                    source: source, id: id, fallbackTitle: nil
                )
                self.detail = result
                self.isLoading = false

                // 后台搜索其他来源
                await searchOtherSources(title: result.title, excludeSource: source, excludeId: id)
            } catch {
                self.isLoading = false
            }
        }
    }

    func toggleFavorite() {
        guard let detail = detail else { return }

        if isFavorited {
            PersistenceService.shared.deleteFavorite(source: currentSource, id: currentId)
        } else {
            let favorite = Favorite(
                sourceName: detail.sourceName,
                totalEpisodes: detail.episodes.count,
                title: detail.title,
                year: detail.year,
                cover: detail.poster,
                saveTime: Date().timeIntervalSince1970 * 1000,
                searchTitle: detail.title
            )
            PersistenceService.shared.saveFavorite(source: currentSource, id: currentId, favorite: favorite)
        }
        isFavorited.toggle()
    }

    private func searchOtherSources(title: String, excludeSource: String, excludeId: String) async {
        let result = await SourceSearchService.shared.searchAllSourcesSimple(query: title)
        let otherSources = result.results.filter { $0.source != excludeSource || $0.id != excludeId }
        self.allSources = otherSources
    }
}
