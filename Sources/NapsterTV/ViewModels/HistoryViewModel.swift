import Foundation

final class HistoryViewModel: ObservableObject {
    @Published var records: [(key: String, record: PlayRecord)] = []

    func loadRecords() {
        let allRecords = PersistenceService.shared.getAllPlayRecords()
        records = allRecords
            .sorted { $0.value.saveTime > $1.value.saveTime }
            .map { (key: $0.key, record: $0.value) }
    }

    func deleteRecord(source: String, id: String) {
        PersistenceService.shared.deletePlayRecord(source: source, id: id)
        loadRecords()
    }

    func clearAll() {
        PersistenceService.shared.clearAllPlayRecords()
        records = []
    }
}
