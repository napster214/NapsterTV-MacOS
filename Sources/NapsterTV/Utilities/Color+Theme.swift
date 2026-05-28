import SwiftUI

extension Color {
    // 主题色
    static let themePrimary = Color(hex: "3D8BFF")
    static let themePrimaryLight = Color(hex: "1A2A4A")
    static let themePrimaryDark = Color(hex: "2A6AE0")

    // 文字色
    static let themeText = Color(hex: "FFFFFF")
    static let themeTextSecondary = Color(hex: "C7C9D0")
    static let themeTextHint = Color(hex: "8E8E93")

    // 背景色
    static let themeBackground = Color(hex: "0A0A0F")
    static let themeWhite = Color(hex: "1C1C24")
    static let themeCard = Color(hex: "15151C")

    // 边框色
    static let themeBorder = Color(hex: "2C2C36")
    static let themeDivider = Color(hex: "23232C")

    // 功能色
    static let themeSuccess = Color(hex: "4CAF50")
    static let themeWarning = Color(hex: "FF9800")
    static let themeError = Color(hex: "F44336")

    // 播放器
    static let themePlayerBackground = Color(hex: "050608")
    static let themePlayerOverlay = Color.black.opacity(0.5)

    // 海报占位
    static let themePosterPlaceholder = Color(hex: "1C1C24")

    // 骨架屏
    static let themeSkeletonBase = Color(hex: "1C1C24")
    static let themeSkeletonShine = Color(hex: "2C2C36")

    // 评分徽章 — 深色适配
    static let themeScoreHighBackground = Color(hex: "1B3A1E")
    static let themeScoreHighText = Color(hex: "66BB6A")
    static let themeScoreMidBackground = Color(hex: "3E2A0A")
    static let themeScoreMidText = Color(hex: "FFB74D")
    static let themeScoreLowBackground = Color(hex: "3A1515")
    static let themeScoreLowText = Color(hex: "EF5350")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
