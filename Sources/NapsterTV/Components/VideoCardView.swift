import SwiftUI
import Kingfisher

struct VideoCardView: View {
    let title: String
    let poster: String
    let year: String
    let rate: String?
    let sourceName: String?
    let totalEpisodes: Int?
    let currentEpisode: Int?
    let mode: VideoCardMode

    enum VideoCardMode {
        case search, favorite, history
    }

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 海报
            ZStack(alignment: .topLeading) {
                PosterImageView(urlString: poster)
                    .frame(width: Constants.posterWidth, height: Constants.posterHeight)
                    .clipped()
                    .cornerRadius(8)

                // 评分徽章
                if let rate = rate, !rate.isEmpty {
                    RatingBadgeView(rate: rate)
                        .padding(4)
                }

                // 年份徽章
                if !year.isEmpty && year != "unknown" {
                    Text(year)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(4)
                        .padding(4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }

                // 剧集数徽章
                if let total = totalEpisodes, total > 0 {
                    Text("\(total)集")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.themePrimary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.themePrimaryLight)
                        .cornerRadius(4)
                        .padding(4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
            }
            .frame(width: Constants.posterWidth, height: Constants.posterHeight)
            .background(Color.themePosterPlaceholder)
            .cornerRadius(8)

            // 标题
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.themeText)
                .lineLimit(1)
                .frame(width: Constants.posterWidth, alignment: .leading)

            // 副信息
            if mode == .history, let current = currentEpisode, let total = totalEpisodes {
                Text("第\(current)/\(total)集")
                    .font(.system(size: 11))
                    .foregroundColor(.themeTextHint)
            } else if let source = sourceName {
                Text(source)
                    .font(.system(size: 11))
                    .foregroundColor(.themeTextHint)
                    .lineLimit(1)
            }
        }
        .frame(width: Constants.posterWidth)
        .scaleEffect(isHovered ? 1.04 : 1.0)
        .shadow(color: .black.opacity(isHovered ? 0.4 : 0), radius: 12, y: 6)
        .animation(.easeOut(duration: 0.18), value: isHovered)
        .onHover { isHovered = $0 }
    }
}
