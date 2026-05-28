import Foundation

// 持久化存储服务，封装 UserDefaults
final class PersistenceService {
    static let shared = PersistenceService()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSLock()

    private init() {}

    // MARK: - 通用读写

    private func getJSON<T: Decodable>(key: String, fallback: T) -> T {
        guard let data = defaults.data(forKey: key) else { return fallback }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            return fallback
        }
    }

    private func setJSON<T: Encodable>(key: String, value: T) {
        do {
            let data = try encoder.encode(value)
            defaults.set(data, forKey: key)
        } catch {
            print("[PersistenceService] 写入失败: \(error)")
        }
    }

    // MARK: - 播放记录

    func getAllPlayRecords() -> [String: PlayRecord] {
        getJSON(key: Constants.storagePlayRecords, fallback: [:])
    }

    func savePlayRecord(source: String, id: String, record: PlayRecord) {
        lock.lock()
        defer { lock.unlock() }
        var records = getAllPlayRecords()
        let key = storageKey(source: source, id: id)
        var updatedRecord = record
        if updatedRecord.saveTime == 0 {
            updatedRecord = PlayRecord(
                title: record.title,
                sourceName: record.sourceName,
                cover: record.cover,
                year: record.year,
                index: record.index,
                totalEpisodes: record.totalEpisodes,
                playTime: record.playTime,
                totalTime: record.totalTime,
                saveTime: Date().timeIntervalSince1970 * 1000,
                searchTitle: record.searchTitle
            )
        }
        records[key] = updatedRecord
        setJSON(key: Constants.storagePlayRecords, value: records)
    }

    func deletePlayRecord(source: String, id: String) {
        lock.lock()
        defer { lock.unlock() }
        var records = getAllPlayRecords()
        records.removeValue(forKey: storageKey(source: source, id: id))
        setJSON(key: Constants.storagePlayRecords, value: records)
    }

    func clearAllPlayRecords() {
        defaults.removeObject(forKey: Constants.storagePlayRecords)
    }

    // MARK: - 收藏

    func getAllFavorites() -> [String: Favorite] {
        getJSON(key: Constants.storageFavorites, fallback: [:])
    }

    func saveFavorite(source: String, id: String, favorite: Favorite) {
        lock.lock()
        defer { lock.unlock() }
        var favorites = getAllFavorites()
        let key = storageKey(source: source, id: id)
        var updatedFavorite = favorite
        if updatedFavorite.saveTime == 0 {
            updatedFavorite = Favorite(
                sourceName: favorite.sourceName,
                totalEpisodes: favorite.totalEpisodes,
                title: favorite.title,
                year: favorite.year,
                cover: favorite.cover,
                saveTime: Date().timeIntervalSince1970 * 1000,
                searchTitle: favorite.searchTitle
            )
        }
        favorites[key] = updatedFavorite
        setJSON(key: Constants.storageFavorites, value: favorites)
    }

    func deleteFavorite(source: String, id: String) {
        lock.lock()
        defer { lock.unlock() }
        var favorites = getAllFavorites()
        favorites.removeValue(forKey: storageKey(source: source, id: id))
        setJSON(key: Constants.storageFavorites, value: favorites)
    }

    func isFavorited(source: String, id: String) -> Bool {
        getAllFavorites()[storageKey(source: source, id: id)] != nil
    }

    func clearAllFavorites() {
        defaults.removeObject(forKey: Constants.storageFavorites)
    }

    // MARK: - 搜索历史

    func getSearchHistory() -> [String] {
        getJSON(key: Constants.storageSearchHistory, fallback: [])
    }

    func addSearchHistory(keyword: String) {
        lock.lock()
        defer { lock.unlock() }
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var history = getSearchHistory()
        history.removeAll { $0 == trimmed }
        history.insert(trimmed, at: 0)
        if history.count > Constants.maxSearchHistory {
            history = Array(history.prefix(Constants.maxSearchHistory))
        }
        setJSON(key: Constants.storageSearchHistory, value: history)
    }

    func deleteSearchHistory(keyword: String) {
        lock.lock()
        defer { lock.unlock() }
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var history = getSearchHistory()
        history.removeAll { $0 == trimmed }
        setJSON(key: Constants.storageSearchHistory, value: history)
    }

    func clearSearchHistory() {
        defaults.removeObject(forKey: Constants.storageSearchHistory)
    }

    // MARK: - 管理配置

    func getAdminConfig() -> AdminConfig? {
        getJSON(key: Constants.storageAdminConfig, fallback: nil)
    }

    func setAdminConfig(_ config: AdminConfig) {
        setJSON(key: Constants.storageAdminConfig, value: config)
    }

    // MARK: - 辅助方法

    private func storageKey(source: String, id: String) -> String {
        "\(source)+\(id)"
    }
}
