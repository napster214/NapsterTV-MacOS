import SwiftUI

struct SourcesManageView: View {
    @StateObject private var viewModel = SourcesManageViewModel()
    @State private var showingAddSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showDeleteConfirm = false
    @State private var pendingDeleteSource: SourceConfig?

    var body: some View {
        ZStack(alignment: .bottom) {
            if viewModel.sources.isEmpty {
                EmptyStateView(text: "还没有添加视频源", systemImageName: "server.rack")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.sources) { source in
                            sourceRow(source: source)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 80)
                }
            }

            // 添加按钮
            Button {
                viewModel.isNewSource = true
                viewModel.editingSource = nil
                showingAddSheet = true
            } label: {
                Text("+ 添加视频源")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.themePrimary)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Color.themeBackground)
        .navigationTitle("视频源管理")
        .sheet(isPresented: $showingAddSheet) {
            SourceFormView(
                source: viewModel.editingSource,
                isNew: viewModel.isNewSource
            ) { key, name, api, detail in
                viewModel.saveSource(key: key, name: name, api: api, detail: detail)
                showingAddSheet = false
            }
        }
        .alert("验证结果", isPresented: $showingAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            viewModel.loadSources()
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("删除", role: .destructive) {
                if let source = pendingDeleteSource {
                    viewModel.deleteSource(source)
                    pendingDeleteSource = nil
                }
            }
            Button("取消", role: .cancel) {
                pendingDeleteSource = nil
            }
        } message: {
            if let source = pendingDeleteSource {
                Text("确定要删除「\(source.name)」吗？此操作不可撤销。")
            }
        }
        .onChange(of: viewModel.validationMessage) { _, newValue in
            if let msg = newValue {
                alertMessage = msg
                showingAlert = true
                viewModel.validationMessage = nil
            }
        }
    }

    private func sourceRow(source: SourceConfig) -> some View {
        VStack(spacing: 0) {
            // 主行
            Button {
                viewModel.toggleSource(source)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.themeText)
                        Text(source.api)
                            .font(.system(size: 12))
                            .foregroundColor(.themeTextHint)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(source.disabled ? "已禁用" : "已启用")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(source.disabled ? .themeTextHint : .themeSuccess)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(source.disabled ? Color.themeDivider : Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            Divider().padding(.horizontal, 12)

            // 操作行
            HStack(spacing: 16) {
                Button("编辑") {
                    viewModel.isNewSource = false
                    viewModel.editingSource = source
                    showingAddSheet = true
                }
                .font(.system(size: 13))
                .foregroundColor(.themePrimary)

                Button("验证") {
                    viewModel.validateSource(source)
                }
                .font(.system(size: 13))
                .foregroundColor(.themePrimary)

                Button("删除", role: .destructive) {
                    pendingDeleteSource = source
                    showDeleteConfirm = true
                }
                .font(.system(size: 13))
                .foregroundColor(.themeError)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(Color.themeCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeBorder, lineWidth: 0.5))
    }
}

// 源编辑/添加表单
struct SourceFormView: View {
    let source: SourceConfig?
    let isNew: Bool
    let onSave: (String, String, String, String?) -> Void

    @State private var key = ""
    @State private var name = ""
    @State private var api = ""
    @State private var detail = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(isNew ? "添加源" : "编辑源")
                .font(.system(size: 18, weight: .bold))
                .padding(.top, 16)

            Form {
                TextField("标识 (key)", text: $key)
                    .disableAutocorrection(true)
                    .disabled(!isNew)
                TextField("名称", text: $name)
                TextField("API 地址", text: $api)
                    .disableAutocorrection(true)
                TextField("详情页地址（可选）", text: $detail)
                    .disableAutocorrection(true)
            }
            .formStyle(.grouped)

            HStack(spacing: 12) {
                Button("取消") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])

                Button("保存") {
                    onSave(key, name, api, detail.isEmpty ? nil : detail)
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(key.isEmpty || name.isEmpty || api.isEmpty)
            }
            .padding(.bottom, 16)
        }
        .frame(width: 450, height: 350)
        .onAppear {
            if let source = source {
                key = source.key
                name = source.name
                api = source.api
                detail = source.detail ?? ""
            }
        }
    }
}
