import SwiftUI

struct SkeletonGridView: View {
    var count: Int = 6
    var columns: Int = 3

    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: columns)
    }

    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 12) {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonCardView()
            }
        }
    }
}
