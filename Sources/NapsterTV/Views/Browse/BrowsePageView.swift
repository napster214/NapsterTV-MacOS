import SwiftUI

struct BrowsePageView: View {
    let title: String
    let subtitle: String
    let tags: [String]
    let type: String

    @State private var selectedTag: String
    @State private var items: [DoubanItem] = []
    @State private var isLoading = false
    @State private var hasMore = true
    @State private var currentPage = 0

    private let columns = [GridItem(.adaptive(minimum: Constants.posterWidth, maximum: Constants.posterWidth + 20), spacing: 16)]

    init(title: String, subtitle: String, tags: [String], type: String, initialTag: String = "热门") {
        self.title = title
        self.subtitle = subtitle
        self.tags = tags
        self.type = type
        self._selectedTag = State(initialValue: initialTag)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标签筛选栏
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagPillView(title: tag, isSelected: selectedTag == tag) {
                            selectTag(tag)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            // 内容网格
            if isLoading && items.isEmpty {
                SkeletonGridView(count: 10, columns: 5)
                    .padding(16)
                    .frame(maxHeight: .infinity, alignment: .top)
            } else if items.isEmpty {
                EmptyStateView(text: "暂无内容", systemImageName: "film")
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(items) { item in
                            NavigationLink(value: Route.play(
                                source: "", id: item.id,
                                title: item.title, year: item.year,
                                searchTitle: item.title, prefer: true
                            )) {
                                browseCard(item)
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                if item.id == items.last?.id && hasMore && !isLoading {
                                    loadMore()
                                }
                            }
                        }
                    }
                    .padding(16)

                    if isLoading {
                        ProgressView()
                            .padding()
                    }

                    if !hasMore {
                        Text("没有更多了")
                            .font(.system(size: 13))
                            .foregroundColor(.themeTextHint)
                            .padding()
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .background(Color.themeBackground)
        .navigationTitle(title)
        .onAppear {
            if items.isEmpty && !isLoading {
                loadData()
            }
        }
    }

    private func browseCard(_ item: DoubanItem) -> some View {
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

            HStack(spacing: 4) {
                if !item.year.isEmpty {
                    Text(item.year)
                        .font(.system(size: 11))
                        .foregroundColor(.themeTextHint)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                if !item.rate.isEmpty {
                    RatingBadgeView(rate: item.rate)
                }
            }
            .frame(width: Constants.posterWidth, height: 18)
        }
        .frame(width: Constants.posterWidth)
    }

    private func selectTag(_ tag: String) {
        selectedTag = tag
        items = []
        currentPage = 0
        hasMore = true
        loadData()
    }

    private func loadData() {
        guard !isLoading else { return }
        isLoading = true

        Task {
            do {
                let result = try await DoubanAPIService.shared.getDoubanList(
                    type: type,
                    tag: selectedTag,
                    pageStart: currentPage * Constants.doubanPageSize
                )
                DispatchQueue.main.async {
                    if self.currentPage == 0 {
                        self.items = result.list
                    } else {
                        self.items.append(contentsOf: result.list)
                    }
                    self.hasMore = result.list.count >= Constants.doubanPageSize
                    self.currentPage += 1
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }
    }

    private func loadMore() {
        loadData()
    }
}
