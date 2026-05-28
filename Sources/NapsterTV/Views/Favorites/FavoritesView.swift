import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @State private var showClearAllConfirm = false

    private let columns = [GridItem(.adaptive(minimum: Constants.posterWidth, maximum: Constants.posterWidth + 20), spacing: 16)]

    var body: some View {
        VStack(spacing: 0) {
            // 顶部信息栏
            HStack {
                Text("共 \(viewModel.favorites.count) 个收藏")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.themeText)
                Spacer()
                if !viewModel.favorites.isEmpty {
                    Button("清空") {
                        showClearAllConfirm = true
                    }
                    .foregroundColor(.themeError)
                    .font(.system(size: 13))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if viewModel.favorites.isEmpty {
                EmptyStateView(text: "还没有收藏哦", systemImageName: "heart")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.favorites, id: \.key) { item in
                            let keyParts = item.key.components(separatedBy: "+")
                            let favSource = keyParts.count == 2 ? keyParts[0] : ""
                            let favId = keyParts.count == 2 ? keyParts[1] : ""
                            NavigationLink(value: Route.play(
                                source: favSource, id: favId,
                                title: item.favorite.title, year: item.favorite.year,
                                searchTitle: item.favorite.searchTitle, prefer: false
                            )) {
                                VideoCardView(
                                    title: item.favorite.title,
                                    poster: item.favorite.cover,
                                    year: item.favorite.year,
                                    rate: nil,
                                    sourceName: item.favorite.sourceName,
                                    totalEpisodes: item.favorite.totalEpisodes,
                                    currentEpisode: nil,
                                    mode: .favorite
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("取消收藏", role: .destructive) {
                                    let parts = item.key.components(separatedBy: "+")
                                    if parts.count == 2 {
                                        viewModel.removeFavorite(source: parts[0], id: parts[1])
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
        .navigationTitle("收藏")
        .onAppear {
            viewModel.loadFavorites()
        }
        .alert("确认清空", isPresented: $showClearAllConfirm) {
            Button("清空", role: .destructive) {
                viewModel.clearAll()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要清空所有收藏吗？此操作不可撤销。")
        }
    }
}
