import SwiftUI

struct RatingBadgeView: View {
    let rate: String

    private var rateValue: Double {
        Double(rate) ?? 0
    }

    private var backgroundColor: Color {
        if rateValue >= 8 { return .themeScoreHighBackground }
        if rateValue >= 6 { return .themeScoreMidBackground }
        return .themeScoreLowBackground
    }

    private var textColor: Color {
        if rateValue >= 8 { return .themeScoreHighText }
        if rateValue >= 6 { return .themeScoreMidText }
        return .themeScoreLowText
    }

    var body: some View {
        Text(rate)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(textColor)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .cornerRadius(4)
    }
}
