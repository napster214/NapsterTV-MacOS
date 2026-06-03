import SwiftUI

struct ConfigView: View {
    @StateObject private var viewModel = ConfigViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 订阅地址
                VStack(alignment: .leading, spacing: 8) {
                    Text("订阅地址")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.themeText)

                    TextField("输入配置订阅 URL", text: $viewModel.subscriptionUrl)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 14))
                        .disableAutocorrection(true)

                    Button(action: { viewModel.fetchSubscription() }) {
                        Text("获取配置")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.themePrimary)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isLoading)
                }
                .padding(16)
                .background(Color.themeCard)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeBorder, lineWidth: 0.5))

                // 配置 JSON
                VStack(alignment: .leading, spacing: 8) {
                    Text("配置内容 (JSON)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.themeText)

                    TextEditor(text: $viewModel.configContent)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(minHeight: 300)
                        .padding(8)
                        .background(Color.themeBackground)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.themeBorder, lineWidth: 0.5))
                }
                .padding(16)
                .background(Color.themeCard)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeBorder, lineWidth: 0.5))

                // 错误信息
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.themeError)
                        .padding(.horizontal, 16)
                }

                // 保存按钮
                Button(action: {
                    if viewModel.saveConfig() {
                        dismiss()
                    }
                }) {
                    Text("保存配置")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.themePrimary)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)

                // 帮助
                VStack(alignment: .leading, spacing: 8) {
                    Text("配置格式示例：")
                        .font(.system(size: 13))
                        .foregroundColor(.themeTextSecondary)

                    Text("""
                    {
                      "cache_time": 7200,
                      "api_site": {
                        "example": {
                          "api": "https://xxx.com/api.php/provide/vod",
                          "name": "示例资源"
                        }
                      }
                    }
                    """)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.themeTextHint)
                }
                .padding(16)
                .background(Color.themeCard)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeBorder, lineWidth: 0.5))
                .padding(.horizontal, 16)
            }
            .padding(16)
        }
        .background(Color.themeBackground)
        .navigationTitle("配置文件")
        .onAppear {
            viewModel.loadConfig()
        }
    }
}
