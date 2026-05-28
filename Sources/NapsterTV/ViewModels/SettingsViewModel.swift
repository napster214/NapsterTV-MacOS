import Foundation

final class SettingsViewModel: ObservableObject {
    @Published var sourceCount: Int = 0

    func loadSourceCount() {
        sourceCount = ConfigService.shared.getConfig().sourceConfig.count
    }
}
