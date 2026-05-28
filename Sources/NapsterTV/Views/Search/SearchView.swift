import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isLoading = false
    @State private var completedSources = 0
    @State private var totalSources = 0
    @State private var searchHistory: [String] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var showClearHistoryConfirm = false

    private let columns = [GridItem(.adaptive(minimum: Constants.posterWidth, maximum: Constants.posterWidth + 20), spacing: 16)]

    var body: some View {
        VStack(spacing: 0) {
            // 搜索进度
            if isLoading && totalSources > 0 {
                SearchProgressBarView(
                    completed: completedSources,
                    total: totalSources
                )
            }

            if searchResults.isEmpty && !isLoading {
                // 搜索历史
                if !searchHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("搜索历史")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.themeText)
                            Spacer()
                            Button("清空") {
                                showClearHistoryConfirm = true
                            }
                            .foregroundColor(.themeError)
                            .font(.system(size: 13))
                        }
                        .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 8) {
                                ForEach(searchHistory, id: \.self) { keyword in
                                    Button {
                                        searchText = keyword
                                        performSearch()
                                    } label: {
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
                                    .contextMenu {
                                        Button("删除此记录", role: .destructive) {
                                            PersistenceService.shared.deleteSearchHistory(keyword: keyword)
                                            searchHistory = PersistenceService.shared.getSearchHistory()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 16)
                } else {
                    EmptyStateView(text: "搜索你喜欢的影视", systemImageName: "magnifyingglass")
                }
            } else {
                // 搜索结果
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(searchResults) { result in
                            NavigationLink(value: Route.play(
                                source: result.source, id: result.id,
                                title: result.title, year: result.year,
                                searchTitle: result.title, prefer: false
                            )) {
                                VideoCardView(
                                    title: result.title,
                                    poster: result.poster,
                                    year: result.year,
                                    rate: nil,
                                    sourceName: result.sourceName,
                                    totalEpisodes: result.episodes.count,
                                    currentEpisode: nil,
                                    mode: .search
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Color.themeBackground)
        .navigationTitle("搜索")
        .searchable(text: $searchText, prompt: "搜索片名、演员或关键词")
        .onSubmit(of: .search) {
            performSearch()
        }
        .onAppear {
            searchHistory = PersistenceService.shared.getSearchHistory()
        }
        .alert("确认清空", isPresented: $showClearHistoryConfirm) {
            Button("清空", role: .destructive) {
                PersistenceService.shared.clearSearchHistory()
                searchHistory = []
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要清空所有搜索历史吗？此操作不可撤销。")
        }
    }

    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        PersistenceService.shared.addSearchHistory(keyword: query)
        searchHistory = PersistenceService.shared.getSearchHistory()

        searchResults = []
        isLoading = true
        completedSources = 0
        totalSources = 0

        searchTask?.cancel()
        searchTask = Task {
            let result = await SourceSearchService.shared.searchAllSourcesSimple(query: query) { progress in
                DispatchQueue.main.async {
                    completedSources = progress.completedSources
                    totalSources = progress.totalSources
                }
            }
            guard !Task.isCancelled else { return }
            DispatchQueue.main.async {
                searchResults = result.results
                isLoading = false
            }
        }
    }
}
