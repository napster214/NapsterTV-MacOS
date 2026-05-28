import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var showClearAllConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("共 \(viewModel.records.count) 条记录")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.themeText)
                Spacer()
                if !viewModel.records.isEmpty {
                    Button("清空") {
                        showClearAllConfirm = true
                    }
                    .foregroundColor(.themeError)
                    .font(.system(size: 13))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if viewModel.records.isEmpty {
                EmptyStateView(text: "还没有播放记录", systemImageName: "clock")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.records, id: \.key) { item in
                            let keyParts = item.key.components(separatedBy: "+")
                            let recordSource = keyParts.count == 2 ? keyParts[0] : ""
                            let recordId = keyParts.count == 2 ? keyParts[1] : ""
                            NavigationLink(value: Route.play(
                                source: recordSource, id: recordId,
                                title: item.record.title, year: item.record.year,
                                searchTitle: item.record.searchTitle, prefer: false
                            )) {
                                HistoryListItemView(record: item.record)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("删除", role: .destructive) {
                                    let parts = item.key.components(separatedBy: "+")
                                    if parts.count == 2 {
                                        viewModel.deleteRecord(source: parts[0], id: parts[1])
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Color.themeBackground)
        .navigationTitle("播放记录")
        .onAppear {
            viewModel.loadRecords()
        }
        .alert("确认清空", isPresented: $showClearAllConfirm) {
            Button("清空", role: .destructive) {
                viewModel.clearAll()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要清空所有播放记录吗？此操作不可撤销。")
        }
    }
}

// 历史记录列表项
struct HistoryListItemView: View {
    let record: PlayRecord

    var body: some View {
        HStack(spacing: 12) {
            // 封面
            PosterImageView(urlString: record.cover)
                .frame(width: 70, height: 100)
                .clipped()
                .cornerRadius(8)
                .background(Color.themePosterPlaceholder)

            // 信息
            VStack(alignment: .leading, spacing: 6) {
                Text(record.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.themeText)
                    .lineLimit(1)

                Text("\(record.sourceName) · 第\(record.index)/\(record.totalEpisodes)集")
                    .font(.system(size: 13))
                    .foregroundColor(.themeTextSecondary)

                // 播放进度
                if record.totalTime > 0 {
                    ProgressBarView(
                        progress: record.playTime / record.totalTime,
                        color: .themePrimary,
                        height: 4
                    )
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.themeTextHint)
        }
        .padding(12)
        .background(Color.themeWhite)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.themeBorder, lineWidth: 0.5)
        )
    }
}
