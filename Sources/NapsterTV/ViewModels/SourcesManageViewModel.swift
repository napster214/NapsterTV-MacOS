import Foundation

@MainActor
final class SourcesManageViewModel: ObservableObject {
    @Published var sources: [SourceConfig] = []
    @Published var isLoading = false
    @Published var editingSource: SourceConfig?
    @Published var isNewSource = false
    @Published var validationMessage: String?

    func loadSources() {
        sources = ConfigService.shared.getConfig().sourceConfig
    }

    func toggleSource(_ source: SourceConfig) {
        guard let index = sources.firstIndex(where: { $0.key == source.key }) else { return }
        sources[index] = SourceConfig(
            key: source.key, name: source.name, api: source.api,
            detail: source.detail, from: source.from, disabled: !source.disabled
        )
        ConfigService.shared.updateSourceConfig(sources)
    }

    func deleteSource(_ source: SourceConfig) {
        sources.removeAll { $0.key == source.key }
        ConfigService.shared.updateSourceConfig(sources)
    }

    func saveSource(key: String, name: String, api: String, detail: String?) {
        if isNewSource {
            let newSource = SourceConfig(
                key: key.trimmingCharacters(in: .whitespaces),
                name: name.trimmingCharacters(in: .whitespaces),
                api: api.trimmingCharacters(in: .whitespaces),
                detail: detail?.trimmingCharacters(in: .whitespaces).isEmpty == true ? nil : detail?.trimmingCharacters(in: .whitespaces),
                from: .custom,
                disabled: false
            )
            sources.append(newSource)
        } else if let index = sources.firstIndex(where: { $0.key == key }) {
            sources[index] = SourceConfig(
                key: key, name: name, api: api, detail: detail,
                from: sources[index].from, disabled: sources[index].disabled
            )
        }
        ConfigService.shared.updateSourceConfig(sources)
        editingSource = nil
    }

    func validateSource(_ source: SourceConfig) {
        isLoading = true
        validationMessage = nil

        Task {
            do {
                let apiSite = ApiSite(key: source.key, api: source.api, name: source.name, detail: source.detail)
                let results = try await MacCMSAPIService.shared.searchFromApi(apiSite: apiSite, query: "灵笼")
                self.isLoading = false
                self.validationMessage = results.isEmpty ? "验证通过，但未返回结果" : "验证成功，找到 \(results.count) 条结果"
            } catch {
                self.isLoading = false
                self.validationMessage = "验证失败: \(error.localizedDescription)"
            }
        }
    }
}
