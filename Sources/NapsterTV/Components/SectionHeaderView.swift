import SwiftUI

struct SectionHeaderView: View {
    let title: String
    var showMore: Bool = false
    var onMore: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(.themeText)

            Spacer()

            if showMore {
                Button(action: { onMore?() }) {
                    HStack(spacing: 2) {
                        Text("更多")
                            .font(.system(size: 13))
                            .foregroundColor(.themeTextSecondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.themeTextSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }
}
