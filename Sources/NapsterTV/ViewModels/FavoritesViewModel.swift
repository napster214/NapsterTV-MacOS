import Foundation

final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [(key: String, favorite: Favorite)] = []

    func loadFavorites() {
        let allFavorites = PersistenceService.shared.getAllFavorites()
        favorites = allFavorites
            .sorted { $0.value.saveTime > $1.value.saveTime }
            .map { (key: $0.key, favorite: $0.value) }
    }

    func removeFavorite(source: String, id: String) {
        PersistenceService.shared.deleteFavorite(source: source, id: id)
        loadFavorites()
    }

    func clearAll() {
        PersistenceService.shared.clearAllFavorites()
        favorites = []
    }
}
