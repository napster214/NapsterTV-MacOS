import SwiftUI

struct SiteConfigView: View {
    @StateObject private var viewModel = SiteConfigViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            // 基本设置
            Section {
                TextField("站点名称", text: $viewModel.siteConfig.siteName)
                TextField("公告", text: $viewModel.siteConfig.announcement, axis: .vertical)
                    .lineLimit(2...5)
                Stepper("搜索最大页数: \(viewModel.siteConfig.searchDownstreamMaxPage)",
                        value: $viewModel.siteConfig.searchDownstreamMaxPage, in: 1...20)
                Stepper("接口缓存时间: \(viewModel.siteConfig.siteInterfaceCacheTime) 秒",
                        value: $viewModel.siteConfig.siteInterfaceCacheTime, in: 60...86400)
                Toggle("关闭黄色过滤", isOn: $viewModel.siteConfig.disableYellowFilter)
                Toggle("流式搜索", isOn: $viewModel.siteConfig.fluidSearch)
            }

            // 豆瓣数据源
            Section("豆瓣数据源") {
                Picker("数据源代理", selection: $viewModel.siteConfig.doubanProxyType) {
                    ForEach(DoubanProxyType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }

                if viewModel.siteConfig.doubanProxyType == .custom {
                    TextField("自定义代理 URL", text: $viewModel.siteConfig.doubanProxy)
                        .disableAutocorrection(true)
                }

                Picker("图片代理", selection: $viewModel.siteConfig.doubanImageProxyType) {
                    ForEach(DoubanProxyType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }

                if viewModel.siteConfig.doubanImageProxyType == .custom {
                    TextField("自定义图片代理 URL", text: $viewModel.siteConfig.doubanImageProxy)
                        .disableAutocorrection(true)
                }
            }

            // 保存按钮
            Section {
                Button {
                    viewModel.saveConfig()
                    dismiss()
                } label: {
                    Text("保存配置")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.themePrimary)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("站点配置")
        .onAppear {
            viewModel.loadConfig()
        }
    }
}
