import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero 轮播横幅
                if viewModel.trendingMovies.isEmpty {
                    // 加载中骨架
                    Rectangle()
                        .fill(Color.themeCard)
                        .frame(height: 420)
                } else {
                    HeroBannerView(items: viewModel.trendingMovies)
                }

                // 继续观看
                if !viewModel.recentHistory.isEmpty {
                    recentHistorySection
                }

                // 热门电影
                if !viewModel.trendingMovies.isEmpty {
                    trendingSection(title: "热门电影", items: viewModel.trendingMovies, type: "movie")
                }

                // 热门剧集
                if !viewModel.trendingTVShows.isEmpty {
                    trendingSection(title: "热门剧集", items: viewModel.trendingTVShows, type: "tv")
                }

                // 我的收藏
                if !viewModel.favorites.isEmpty {
                    favoritesSection
                }

                // 搜索历史
                if !viewModel.searchHistory.isEmpty {
                    searchHistorySection
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationTitle("NapsterTV")
        .onAppear {
            viewModel.loadHomeData()
        }
    }

    // MARK: - 热门内容

    private func trendingSection(title: String, items: [DoubanItem], type: String) -> some View {
        let columns = [GridItem(.adaptive(minimum: Constants.posterWidth, maximum: Constants.posterWidth + 20), spacing: 16)]
        return VStack(spacing: 12) {
            SectionHeaderView(title: title)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items) { item in
                    NavigationLink(value: Route.play(
                        source: "", id: item.id,
                        title: item.title, year: item.year,
                        searchTitle: item.title, prefer: true
                    )) {
                        doubanCard(item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func doubanCard(_ item: DoubanItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            PosterImageView(urlString: item.cover)
                .frame(width: Constants.posterWidth, height: Constants.posterHeight)
                .clipped()
                .background(Color.themePosterPlaceholder)
                .cornerRadius(8)

            Text(item.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.themeText)
                .lineLimit(1)
                .frame(width: Constants.posterWidth, alignment: .leading)

            if !item.rate.isEmpty {
                RatingBadgeView(rate: item.rate)
                    .frame(height: 18, alignment: .leading)
            } else {
                Color.clear.frame(height: 18)
            }
        }
        .frame(width: Constants.posterWidth)
        .contentShape(Rectangle())
    }

    // MARK: - 继续观看

    private var recentHistorySection: some View {
        let columns = [GridItem(.adaptive(minimum: Constants.posterWidth, maximum: Constants.posterWidth + 20), spacing: 16)]
        return VStack(spacing: 12) {
            SectionHeaderView(title: "继续观看")

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.recentHistory.indices, id: \.self) { index in
                    let record = viewModel.recentHistory[index]
                    NavigationLink(value: Route.play(
                        source: "", id: "",
                        title: record.title, year: record.year,
                        searchTitle: record.searchTitle, prefer: false
                    )) {
                        VStack(alignment: .leading, spacing: 6) {
                            ZStack(alignment: .bottom) {
                                PosterImageView(urlString: record.cover)
                                    .frame(width: Constants.posterWidth, height: Constants.posterHeight)
                                    .clipped()
                                    .background(Color.themePosterPlaceholder)
                                    .cornerRadius(8)

                                if record.totalTime > 0 {
                                    ProgressBarView(
                                        progress: record.playTime / record.totalTime,
                                        color: .themePrimary,
                                        height: 3
                                    )
                                    .padding(.horizontal, 4)
                                    .padding(.bottom, 4)
                                }
                            }

                            Text(record.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.themeText)
                                .lineLimit(1)
                                .frame(width: Constants.posterWidth, alignment: .leading)

                            Text("第\(record.index)/\(record.totalEpisodes)集")
                                .font(.system(size: 11))
                                .foregroundColor(.themeTextHint)
                        }
                        .frame(width: Constants.posterWidth)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - 我的收藏

    private var favoritesSection: some View {
        let columns = [GridItem(.adaptive(minimum: Constants.posterWidth, maximum: Constants.posterWidth + 20), spacing: 16)]
        return VStack(spacing: 12) {
            SectionHeaderView(title: "我的收藏")

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.favorites, id: \.saveTime) { fav in
                    NavigationLink(value: Route.play(
                        source: "", id: "",
                        title: fav.title, year: fav.year,
                        searchTitle: fav.searchTitle, prefer: false
                    )) {
                        VStack(alignment: .leading, spacing: 6) {
                            PosterImageView(urlString: fav.cover)
                                .frame(width: Constants.posterWidth, height: Constants.posterHeight)
                                .clipped()
                                .background(Color.themePosterPlaceholder)
                                .cornerRadius(8)

                            Text(fav.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.themeText)
                                .lineLimit(1)
                                .frame(width: Constants.posterWidth, alignment: .leading)

                            if !fav.sourceName.isEmpty {
                                Text(fav.sourceName)
                                    .font(.system(size: 11))
                                    .foregroundColor(.themeTextHint)
                                    .lineLimit(1)
                                    .frame(width: Constants.posterWidth, alignment: .leading)
                            }
                        }
                        .frame(width: Constants.posterWidth)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - 搜索历史

    private var searchHistorySection: some View {
        VStack(spacing: 12) {
            SectionHeaderView(title: "搜索历史")

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(viewModel.searchHistory, id: \.self) { keyword in
                        NavigationLink(value: Route.play(
                            source: "", id: "",
                            title: keyword, year: "",
                            searchTitle: keyword, prefer: true
                        )) {
                            Text(keyword)
                                .font(.system(size: 13))
                                .foregroundColor(.themeText)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.themeWhite)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.themeBorder, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
