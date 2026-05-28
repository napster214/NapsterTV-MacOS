import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // 标题
            VStack(alignment: .leading, spacing: 4) {
                Text("设置")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.themeText)
                Text("管理配置、站点和视频源")
                    .font(.system(size: 14))
                    .foregroundColor(.themeTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // 菜单
            VStack(spacing: 0) {
                NavigationLink(value: Route.config) {
                    settingsRow(icon: "doc.text", title: "配置文件")
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 44)

                NavigationLink(value: Route.site) {
                    settingsRow(icon: "globe", title: "站点配置")
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 44)

                NavigationLink(value: Route.sources) {
                    HStack {
                        settingsRow(icon: "server.rack", title: "视频源管理")
                        Spacer()
                        Text("\(viewModel.sourceCount) 个源")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.themePrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.themePrimaryLight)
                            .cornerRadius(10)
                    }
                }
                .buttonStyle(.plain)
            }
            .background(Color.themeWhite)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.themeBorder, lineWidth: 0.5)
            )
            .padding(.horizontal, 16)

            Spacer()

            // 版本信息
            Text("NapsterTV macOS v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                .font(.system(size: 13))
                .foregroundColor(.themeTextHint)
                .padding(.bottom, 20)
        }
        .background(Color.themeBackground)
        .navigationTitle("设置")
        .onAppear {
            viewModel.loadSourceCount()
        }
    }

    private func settingsRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.themePrimary)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.themeText)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.themeTextHint)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
