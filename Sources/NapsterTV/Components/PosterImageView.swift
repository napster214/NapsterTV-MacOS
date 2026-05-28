import SwiftUI
import Kingfisher

struct PosterImageView: View {
    let urlString: String

    var body: some View {
        if let url = URL(string: urlString), !urlString.isEmpty {
            KFImage(url)
                .placeholder {
                    Color.themePosterPlaceholder
                        .overlay(
                            Image(systemName: "film")
                                .foregroundColor(.themeTextHint)
                                .font(.title2)
                        )
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Color.themePosterPlaceholder
                .overlay(
                    Image(systemName: "film")
                        .foregroundColor(.themeTextHint)
                        .font(.title2)
                )
        }
    }
}
