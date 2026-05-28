import SwiftUI

struct SkeletonCardView: View {
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geo in
            let posterWidth = geo.size.width
            let posterHeight = posterWidth * 1.5

            VStack(alignment: .leading, spacing: 6) {
                // 海报骨架
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.themeSkeletonBase)
                    .frame(width: posterWidth, height: posterHeight)
                    .opacity(isAnimating ? 0.4 : 1.0)

                // 标题骨架
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.themeSkeletonBase)
                    .frame(height: 14)
                    .frame(maxWidth: 80)

                // 副标题骨架
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.themeSkeletonBase)
                    .frame(height: 12)
                    .frame(maxWidth: 50)
            }
        }
        .aspectRatio(2/3.6, contentMode: .fit)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
