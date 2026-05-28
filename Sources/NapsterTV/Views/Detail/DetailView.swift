import SwiftUI

struct DetailView: View {
    let source: String
    let id: String

    @StateObject private var viewModel = DetailViewModel()

    private let episodeColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 8)

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let detail = viewModel.detail {
                detailContent(detail)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.themeTextHint)
                    Text("加载失败")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.themeTextSecondary)
                    Button("重试") {
                        viewModel.loadDetail(source: source, id: id)
                    }
                    .foregroundColor(.themePrimary)
                    .font(.system(size: 14, weight: .medium))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.themeBackground)
        .navigationTitle("详情")
        .onAppear {
            viewModel.loadDetail(source: source, id: id)
        }
    }

    @ViewBuilder
    private func detailContent(_ detail: SearchResult) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // 头部信息
                HStack(spacing: 16) {
                    PosterImageView(urlString: detail.poster)
                        .frame(width: 120, height: 170)
                        .clipped()
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(detail.title)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.themeText)

                        HStack(spacing: 6) {
                            if !detail.year.isEmpty && detail.year != "unknown" {
                                tagBadge(detail.year)
                            }
                            if let typeName = detail.typeName, !typeName.isEmpty {
                                tagBadge(typeName)
                            }
                            tagBadge(detail.sourceName)
                        }

                        Text("\(detail.episodes.count) 集")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.themePrimary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(Color.themeWhite)
                .cornerRadius(12)

                // 操作按钮
                HStack(spacing: 12) {
                    NavigationLink(value: Route.play(
                        source: source, id: id,
                        title: detail.title, year: detail.year,
                        searchTitle: detail.title, prefer: false
                    )) {
                        Text("播放")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.themeText)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.toggleFavorite()
                    } label: {
                        Text(viewModel.isFavorited ? "已收藏" : "收藏")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(viewModel.isFavorited ? .themePrimary : .themeText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(viewModel.isFavorited ? Color.themePrimaryLight : Color.themeWhite)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(viewModel.isFavorited ? Color.themePrimary : Color.themeBorder, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 16)

                // 选集
                if detail.episodes.count > 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("选集")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.themeText)

                        LazyVGrid(columns: episodeColumns, spacing: 8) {
                            ForEach(0..<detail.episodes.count, id: \.self) { index in
                                NavigationLink(value: Route.play(
                                    source: source, id: id,
                                    title: detail.title, year: detail.year,
                                    searchTitle: detail.title, prefer: false,
                                    episodeIndex: index
                                )) {
                                    Text(index < detail.episodesTitles.count ? detail.episodesTitles[index] : "第\(index + 1)集")
                                        .font(.system(size: 13))
                                        .foregroundColor(.themeText)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.themeBackground)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.themeWhite)
                    .cornerRadius(12)
                }

                // 其他来源
                if !viewModel.allSources.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("其他来源")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.themeText)

                        ForEach(viewModel.allSources) { otherSource in
                            NavigationLink(value: Route.play(
                                source: otherSource.source, id: otherSource.id,
                                title: otherSource.title, year: otherSource.year,
                                searchTitle: otherSource.title, prefer: false
                            )) {
                                HStack {
                                    Text(otherSource.sourceName)
                                        .font(.system(size: 14))
                                        .foregroundColor(.themeText)
                                    Spacer()
                                    Text("\(otherSource.episodes.count) 集")
                                        .font(.system(size: 13))
                                        .foregroundColor(.themeTextSecondary)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(
                                    otherSource.source == source && otherSource.id == id
                                        ? Color.themePrimaryLight
                                        : Color.clear
                                )
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .background(Color.themeWhite)
                    .cornerRadius(12)
                }

                // 简介
                if let desc = detail.desc, !desc.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("简介")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.themeText)
                        Text(desc)
                            .font(.system(size: 14))
                            .foregroundColor(.themeTextSecondary)
                            .lineLimit(nil)
                    }
                    .padding(16)
                    .background(Color.themeWhite)
                    .cornerRadius(12)
                }
            }
            .padding(16)
        }
    }

    private func tagBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.themePrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.themePrimaryLight)
            .cornerRadius(8)
    }
}
