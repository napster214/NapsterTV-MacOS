import Foundation

// 源偏好评分服务
final class SourcePreferenceService {
    static let shared = SourcePreferenceService()

    private let networkClient = NetworkClient.shared

    private init() {}

    struct PreferResult {
        let best: SearchResult
        let allScores: [ScoredSource]
    }

    func preferBestSource(
        sources: [SearchResult],
        onProgress: ((Int, Int) -> Void)? = nil
    ) async -> PreferResult? {
        guard !sources.isEmpty else { return nil }
        if sources.count == 1 {
            return PreferResult(best: sources[0], allScores: [])
        }

        var allResults: [(source: SearchResult, testResult: SourceTestResult?)] = []
        var tested = 0

        let batchSize = Constants.preferenceConcurrency
        for batchStart in stride(from: 0, to: sources.count, by: batchSize) {
            let batch = Array(sources[batchStart..<min(batchStart + batchSize, sources.count)])

            let batchResults = await withTaskGroup(of: (SearchResult, SourceTestResult?).self) { group in
                for source in batch {
                    group.addTask {
                        do {
                            guard !source.episodes.isEmpty else { return (source, nil) }
                            let episodeUrl = source.episodes.count > 1 ? source.episodes[1] : source.episodes[0]
                            let result = try await self.testM3u8Source(m3u8Url: episodeUrl)
                            return (source, result)
                        } catch {
                            return (source, nil)
                        }
                    }
                }

                var results: [(SearchResult, SourceTestResult?)] = []
                for await result in group {
                    results.append(result)
                }
                return results
            }

            for result in batchResults {
                allResults.append(result)
                tested += 1
                onProgress?(tested, sources.count)
            }
        }

        let successful = allResults.compactMap { result -> (SearchResult, SourceTestResult)? in
            guard let testResult = result.testResult else { return nil }
            return (result.source, testResult)
        }

        guard !successful.isEmpty else {
            return PreferResult(best: sources[0], allScores: [])
        }

        let validSpeeds = successful.compactMap { parseSpeedToKBps($0.1.loadSpeed) }.filter { $0 > 0 }
        let maxSpeed = validSpeeds.max() ?? 1024

        let validPings = successful.map { $0.1.pingTime }.filter { $0 > 0 }
        let minPing = validPings.min() ?? 50
        let maxPing = validPings.max() ?? 1000

        let scored = successful.map { source, testResult -> ScoredSource in
            let score = calculateSourceScore(testResult: testResult, maxSpeed: maxSpeed, minPing: minPing, maxPing: maxPing)
            return ScoredSource(source: source, testResult: testResult, score: Int(score))
        }.sorted { $0.score > $1.score }

        return PreferResult(best: scored[0].source, allScores: scored)
    }

    // MARK: - 测速

    private func testM3u8Source(m3u8Url: String) async throws -> SourceTestResult {
        var quality = "未知"
        var loadSpeed = "未知"
        var pingTime: TimeInterval = 0

        let pingStart = Date()
        let manifestText: String

        do {
            manifestText = try await networkClient.getText(url: m3u8Url, headers: ["Accept": "*/*"], timeout: Constants.preferTimeout)
            pingTime = Date().timeIntervalSince(pingStart) * 1000
        } catch {
            pingTime = Date().timeIntervalSince(pingStart) * 1000
            return SourceTestResult(quality: quality, loadSpeed: loadSpeed, pingTime: pingTime)
        }

        quality = M3U8Parser.parseResolutionToQuality(manifestText) ?? M3U8Parser.parseBandwidthToQuality(manifestText)

        if let segmentUrl = M3U8Parser.findFirstSegmentUrl(manifest: manifestText, m3u8Url: m3u8Url) {
            let speedStart = Date()
            do {
                let data = try await networkClient.getData(url: segmentUrl, headers: ["Accept": "*/*"], timeout: Constants.preferTimeout)
                let elapsed = Date().timeIntervalSince(speedStart) * 1000
                if elapsed > 0 {
                    let speedKBps = Double(data.count) / 1024 / (elapsed / 1000)
                    loadSpeed = speedKBps >= 1024
                        ? String(format: "%.1f MB/s", speedKBps / 1024)
                        : String(format: "%.1f KB/s", speedKBps)
                }
            } catch {
                // speed measurement failed
            }
        }

        return SourceTestResult(quality: quality, loadSpeed: loadSpeed, pingTime: pingTime)
    }

    // MARK: - 评分

    private func calculateSourceScore(testResult: SourceTestResult, maxSpeed: Double, minPing: Double, maxPing: Double) -> Double {
        var score: Double = 0

        score += Double(qualityToScore(testResult.quality)) * Constants.preferenceQualityWeight
        score += speedToScore(testResult.loadSpeed, maxSpeed: maxSpeed) * Constants.preferenceSpeedWeight
        score += pingToScore(testResult.pingTime, minPing: minPing, maxPing: maxPing) * Constants.preferenceLatencyWeight

        return score
    }

    private func qualityToScore(_ quality: String) -> Int {
        switch quality {
        case "4K": return 100
        case "2K": return 85
        case "1080p": return 75
        case "720p": return 60
        case "480p": return 40
        case "SD": return 20
        default: return 0
        }
    }

    private func speedToScore(_ loadSpeed: String, maxSpeed: Double) -> Double {
        if loadSpeed == "未知" { return 30 }
        guard let match = loadSpeed.range(of: "^([\\d.]+)\\s*(KB/s|MB/s)$", options: .regularExpression) else { return 30 }

        let speedStr = loadSpeed[match].dropFirst(loadSpeed.distance(from: loadSpeed.startIndex, to: match.lowerBound))
        let parts = speedStr.split(separator: " ")
        guard parts.count == 2, let value = Double(parts[0]) else { return 30 }

        let speedKBps = parts[1].hasPrefix("MB") ? value * 1024 : value
        guard maxSpeed > 0 else { return 30 }
        return min(100, max(0, (speedKBps / maxSpeed) * 100))
    }

    private func pingToScore(_ ping: TimeInterval, minPing: Double, maxPing: Double) -> Double {
        guard ping > 0 else { return 0 }
        guard maxPing > minPing else { return 100 }
        let ratio = (maxPing - ping) / (maxPing - minPing)
        return min(100, max(0, ratio * 100))
    }

    private func parseSpeedToKBps(_ loadSpeed: String) -> Double {
        if loadSpeed == "未知" { return 0 }
        guard let match = loadSpeed.range(of: "^([\\d.]+)\\s*(KB/s|MB/s)$", options: .regularExpression) else { return 0 }

        let speedStr = String(loadSpeed[match])
        let parts = speedStr.split(separator: " ")
        guard parts.count == 2, let value = Double(parts[0]) else { return 0 }
        return parts[1].hasPrefix("MB") ? value * 1024 : value
    }
}
