import Foundation

extension String {
    // 标题规范化：去除空格、破折号、冒号等
    var normalizedTitle: String {
        self.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "：", with: "")
            .replacingOccurrences(of: "—", with: "")
            .replacingOccurrences(of: "–", with: "")
            .replacingOccurrences(of: "·", with: "")
            .replacingOccurrences(of: "・", with: "")
    }

    // 去除季/集后缀
    var withoutSeasonSuffix: String {
        self.replacingOccurrences(
            of: "第[一二三四五六七八九十\\d]+[季部集].*",
            with: "",
            options: .regularExpression
        )
    }

    // 模糊标题匹配
    func matchesTitle(_ other: String) -> Bool {
        let normalizedSelf = self.normalizedTitle
        let normalizedOther = other.normalizedTitle

        if normalizedSelf == normalizedOther { return true }

        // 子串匹配时校验长度比例：短标题至少为长标题的 50%，防止短词误匹配
        if normalizedSelf.contains(normalizedOther) {
            return Double(normalizedOther.count) / Double(normalizedSelf.count) >= 0.5
        }
        if normalizedOther.contains(normalizedSelf) {
            return Double(normalizedSelf.count) / Double(normalizedOther.count) >= 0.5
        }

        // 去除季集后缀后比较
        let selfNoSuffix = normalizedSelf.withoutSeasonSuffix
        let otherNoSuffix = normalizedOther.withoutSeasonSuffix
        if !selfNoSuffix.isEmpty && !otherNoSuffix.isEmpty {
            if selfNoSuffix == otherNoSuffix { return true }
        }

        return false
    }

    // 提取年份
    var extractYear: String {
        if let match = self.range(of: "\\d{4}", options: .regularExpression) {
            return String(self[match])
        }
        return ""
    }
}
