import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    var color: Color = .themePrimary
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                Rectangle()
                    .fill(Color.themeDivider)
                    .frame(height: height)

                // 进度
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * min(max(progress, 0), 1), height: height)
            }
        }
        .frame(height: height)
        .cornerRadius(height / 2)
    }
}
