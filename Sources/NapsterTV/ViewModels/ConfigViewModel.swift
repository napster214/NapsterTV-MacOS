import Foundation

@MainActor
final class ConfigViewModel: ObservableObject {
    @Published var configContent = ""
    @Published var subscriptionUrl = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private static let isoFormatter = ISO8601DateFormatter()

    func loadConfig() {
        let config = ConfigService.shared.getConfig()
        configContent = SubscriptionDecoder.decode(config.configFile)
        subscriptionUrl = config.configSubscription.url
    }

    func fetchSubscription() {
        let url = subscriptionUrl.trimmingCharacters(in: .whitespaces)
        guard !url.isEmpty else {
            errorMessage = "请输入订阅地址"
            return
        }

        let validation = URLValidator.isSafeHttpUrl(url)
        guard validation.valid else {
            errorMessage = validation.reason
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let data = try await NetworkClient.shared.getData(
                    url: url,
                    headers: ["Accept": "*/*"],
                    timeout: 30
                )

                var rawText = ""
                if let text = String(data: data, encoding: .utf8) {
                    rawText = text
                } else if let text = String(data: data, encoding: .ascii) {
                    rawText = text
                } else if let text = String(data: data, encoding: .isoLatin1) {
                    rawText = text
                } else {
                    rawText = String(decoding: data, as: UTF8.self)
                }

                let decoded = SubscriptionDecoder.decode(rawText)
                self.configContent = decoded
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func saveConfig() -> Bool {
        if !configContent.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let data = configContent.data(using: .utf8),
                  (try? JSONSerialization.jsonObject(with: data)) != nil else {
                errorMessage = "JSON 格式不正确"
                return false
            }
        }

        ConfigService.shared.updateConfigFile(configContent, subscription: AdminConfig.ConfigSubscription(
            url: subscriptionUrl,
            autoUpdate: false,
            lastCheck: Self.isoFormatter.string(from: Date())
        ))
        ConfigService.shared.clearCache()
        errorMessage = nil
        return true
    }
}
