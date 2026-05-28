import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Constants.Tab = .home

    var body: some View {
        NavigationSplitView {
            sidebarContent
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            NavigationStack {
                detailContent
                    .navigationDestination(for: Route.self, destination: routeDestination)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    // MARK: - Sidebar

    private var sidebarContent: some View {
        List(selection: $selectedTab) {
            Section("浏览") {
                Label("首页", systemImage: "house")
                    .tag(Constants.Tab.home)
                Label("电影", systemImage: "film")
                    .tag(Constants.Tab.movie)
                Label("剧集", systemImage: "tv")
                    .tag(Constants.Tab.tv)
                Label("搜索", systemImage: "magnifyingglass")
                    .tag(Constants.Tab.search)
            }

            Section("我的") {
                Label("收藏", systemImage: "heart")
                    .tag(Constants.Tab.favorites)
                Label("历史", systemImage: "clock")
                    .tag(Constants.Tab.history)
            }

            Section("系统") {
                Label("设置", systemImage: "gearshape")
                    .tag(Constants.Tab.settings)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("NapsterTV")
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case .home:
            HomeView()
        case .movie:
            BrowsePageView(
                title: "电影",
                subtitle: "来自豆瓣片单的精选内容",
                tags: Constants.movieTags,
                type: "movie"
            )
        case .tv:
            BrowsePageView(
                title: "剧集",
                subtitle: "热门剧集、动画与综艺",
                tags: Constants.tvTags,
                type: "tv"
            )
        case .search:
            SearchView()
        case .favorites:
            FavoritesView()
        case .history:
            HistoryView()
        case .settings:
            SettingsView()
        }
    }

    // MARK: - Route Destination

    @ViewBuilder
    private func routeDestination(_ route: Route) -> some View {
        switch route {
        case .play(let source, let id, let title, let year, let searchTitle, let prefer, _):
            PlayerView(source: source, id: id, title: title, year: year, searchTitle: searchTitle, prefer: prefer)
        case .config:
            ConfigView()
        case .site:
            SiteConfigView()
        case .sources:
            SourcesManageView()
        }
    }
}
