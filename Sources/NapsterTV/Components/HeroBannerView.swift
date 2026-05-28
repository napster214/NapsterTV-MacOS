import SwiftUI
import Kingfisher

// 首页豆瓣热门轮播 Hero 横幅（macOS 版本）
struct HeroBannerView: View {
    let items: [DoubanItem]

    @State private var currentIndex = 0
    @State private var isHovered = false
    @State private var autoRotateTimer: Timer?

    private let rotateInterval: TimeInterval = 6
    private let bannerHeight: CGFloat = 420

    private var displayItems: [DoubanItem] {
        Array(items.prefix(6))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // 当前项内容
            if !displayItems.isEmpty {
                heroItem(displayItems[currentIndex])
                    .id(currentIndex)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: currentIndex)
            }

            // 页面指示器
            if displayItems.count > 1 {
                HStack(spacing: 6) {
                    ForEach(displayItems.indices, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.white : Color.white.opacity(0.35))
                            .frame(width: index == currentIndex ? 8 : 6, height: index == currentIndex ? 8 : 6)
                            .animation(.easeInOut(duration: 0.25), value: currentIndex)
                    }
                }
                .padding(.trailing, 24)
                .padding(.bottom, 14)
            }
        }
        .frame(height: bannerHeight)
        .clipped()
        .onHover { hovering in
            isHovered = hovering
            if hovering { stopTimer() } else { startTimer() }
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    // MARK: - 单个 Hero 项

    private func heroItem(_ item: DoubanItem) -> some View {
        NavigationLink(value: Route.play(
            source: "", id: item.id,
            title: item.title, year: item.year,
            searchTitle: item.title, prefer: true
        )) {
            ZStack(alignment: .bottomLeading) {
                // 背景图 — 轻微模糊，保留画面细节
                KFImage(URL(string: item.cover))
                    .placeholder { Color.themeCard }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: bannerHeight * 2, height: bannerHeight)
                    .blur(radius: 8)
                    .clipped()

                // 左侧渐暗蒙层 — 从左到右由深到透明
                LinearGradient(
                    colors: [Color.black.opacity(0.75), Color.black.opacity(0.3), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                // 底部渐变蒙层
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // 内容区
                HStack(alignment: .bottom, spacing: 24) {
                    // 左侧信息
                    VStack(alignment: .leading, spacing: 12) {
                        Spacer()

                        Text(item.title)
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 8) {
                            if !item.year.isEmpty {
                                Text(item.year)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            if !item.rate.isEmpty {
                                RatingBadgeView(rate: item.rate)
                            }
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("立即播放")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.themePrimary)
                        .cornerRadius(10)
                    }

                    Spacer()

                    // 右侧海报
                    PosterImageView(urlString: item.cover)
                        .frame(width: 220, height: 330)
                        .clipped()
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.5), radius: 16, y: 8)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 自动轮播

    private func startTimer() {
        guard displayItems.count > 1 else { return }
        stopTimer()
        let timer = Timer(timeInterval: rotateInterval, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentIndex = (currentIndex + 1) % displayItems.count
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        autoRotateTimer = timer
    }

    private func stopTimer() {
        autoRotateTimer?.invalidate()
        autoRotateTimer = nil
    }

    private func restartTimer() {
        stopTimer()
        startTimer()
    }
}
