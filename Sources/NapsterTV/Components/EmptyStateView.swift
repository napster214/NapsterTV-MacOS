import SwiftUI

struct EmptyStateView: View {
    let text: String
    var systemImageName: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            if let iconName = systemImageName {
                Image(systemName: iconName)
                    .font(.system(size: 40))
                    .foregroundColor(.themeTextHint)
            }
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.themeTextHint)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
