import Foundation

final class HomeViewModel: ObservableObject {
    @Published var trendingMovies: [DoubanItem] = []
    @Published var trendingTVShows: [DoubanItem] = []
    @Published var recentHistory: [PlayRecord] = []
    @Published var favorites: [Favorite] = []
    @Published var searchHistory: [String] = []
    @Published var isLoading = false

    func loadHomeData() {
        loadTrending()
        loadRecentData()
        searchHistory = PersistenceService.shared.getSearchHistory()
    }

    func refreshData() {
        loadHomeData()
    }

    private func loadTrending() {
        isLoading = true
        Task {
            async let movies = try? DoubanAPIService.shared.getDoubanList(type: "movie", tag: "热门", pageStart: 0, pageLimit: 12)
            async let tvShows = try? DoubanAPIService.shared.getDoubanList(type: "tv", tag: "热门", pageStart: 0, pageLimit: 12)

            let movieResult = await movies
            let tvResult = await tvShows

            DispatchQueue.main.async {
                self.trendingMovies = movieResult?.list ?? []
                self.trendingTVShows = tvResult?.list ?? []
                self.isLoading = false
            }
        }
    }

    private func loadRecentData() {
        let allRecords = PersistenceService.shared.getAllPlayRecords()
        recentHistory = allRecords.values
            .sorted { $0.saveTime > $1.saveTime }
            .prefix(10)
            .map { $0 }

        let allFavorites = PersistenceService.shared.getAllFavorites()
        favorites = allFavorites.values
            .sorted { $0.saveTime > $1.saveTime }
            .prefix(10)
            .map { $0 }
    }
}
