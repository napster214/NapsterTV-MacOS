import SwiftUI

struct SearchProgressBarView: View {
    let completed: Int
    let total: Int

    var body: some View {
        VStack(spacing: 4) {
            ProgressBarView(progress: total > 0 ? Double(completed) / Double(total) : 0)
            Text("\(completed)/\(total) 个源")
                .font(.system(size: 12))
                .foregroundColor(.themeTextHint)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
