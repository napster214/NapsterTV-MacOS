import Foundation
import AVFoundation

final class PlayViewModel: NSObject, ObservableObject {
    @Published var currentSource: SearchResult?
    @Published var currentEpisodeIndex: Int = 0
    @Published var playbackSpeed: Float = 1.0
    @Published var allSources: [SearchResult] = []
    @Published var scoredSources: [ScoredSource] = []
    @Published var isLoading = false
    @Published var isFavorited = false
    @Published var shouldPromptBetterSource = false
    @Published var videoTitle = ""
    @Published var videoYear = ""
    @Published var currentTime: Double = 0
    @Published var totalDuration: Double = 0
    @Published var isPlaying = false
    @Published var player: AVPlayer?
    @Published var errorMessage: String?

    private var searchTitle = ""
    private var preferMode = false
    private var saveTimer: Timer?
    private var timeObserver: Any?
    private var pendingSearchOtherTask: Task<Void, Never>?
    // 记录已经失败过的源，避免来回切换
    private var failedSourceKeys: Set<String> = []

    // AVPlayer
    var playerItem: AVPlayerItem?

    func initialize(source: String, id: String, title: String, year: String, searchTitle: String, prefer: Bool, episodeIndex: Int = 0) {
        self.videoTitle = title
        self.videoYear = year
        self.searchTitle = searchTitle
        self.preferMode = prefer
        self.isLoading = true
        self.failedSourceKeys = []

        print("[PlayVM] initialize source=\(source), id=\(id), title=\(title), prefer=\(prefer)")

        // 检查收藏状态
        isFavorited = PersistenceService.shared.isFavorited(source: source, id: id)

        // 尝试恢复播放位置
        let records = PersistenceService.shared.getAllPlayRecords()
        let recordKey = "\(source)+\(id)"
        if episodeIndex > 0 {
            currentEpisodeIndex = episodeIndex
            currentTime = 0
            print("[PlayVM] 指定集数 episode=\(episodeIndex + 1)")
        } else if let record = records[recordKey] {
            currentEpisodeIndex = record.index - 1
            currentTime = record.playTime
            print("[PlayVM] 恢复进度 episode=\(record.index), time=\(record.playTime)")
        }

        if !source.isEmpty && !id.isEmpty && !prefer {
            print("[PlayVM] 走快速路径 loadFromSource")
            loadFromSource(source: source, id: id)
        } else {
            print("[PlayVM] 走慢速路径 searchAndPlay title=\(searchTitle)")
            searchAndPlay(title: searchTitle)
        }
    }

    func playEpisode(index: Int) {
        saveProgress()
        currentEpisodeIndex = index
        currentTime = 0
        if let source = currentSource, index < source.episodes.count {
            setupPlayer(urlString: source.episodes[index])
        }
    }

    func switchSource(to newSource: SearchResult) {
        saveProgress()
        performSourceSwitch(to: newSource, resumeTime: currentTime)
    }

    private func performSourceSwitch(to newSource: SearchResult, resumeTime: Double) {
        isLoading = true
        Task {
            do {
                print("[PlayVM] performSourceSwitch 重新获取详情 source=\(newSource.source), id=\(newSource.id)")
                let detail = try await MacCMSAPIService.shared.fetchVideoDetail(
                    source: newSource.source, id: newSource.id, fallbackTitle: searchTitle.isEmpty ? nil : searchTitle
                )
                if !self.videoTitle.isEmpty && !self.videoTitle.matchesTitle(detail.title) && !(self.searchTitle.isEmpty ? false : self.searchTitle.matchesTitle(detail.title)) {
                    print("[PlayVM] performSourceSwitch 标题不匹配: '\(self.videoTitle)' vs '\(detail.title)'，取消切换")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "切换失败：源内容不匹配"
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.currentSource = detail
                    if self.currentEpisodeIndex >= detail.episodes.count {
                        self.currentEpisodeIndex = 0
                    }
                    self.currentTime = resumeTime
                    if self.currentEpisodeIndex < detail.episodes.count {
                        self.setupPlayer(urlString: detail.episodes[self.currentEpisodeIndex])
                    }
                    self.isFavorited = PersistenceService.shared.isFavorited(source: detail.source, id: detail.id)
                    print("[PlayVM] performSourceSwitch 完成 episodes=\(detail.episodes.count)")
                }
            } catch {
                print("[PlayVM] performSourceSwitch 获取详情失败 error=\(error), 使用内存数据切换")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.currentSource = newSource
                    if self.currentEpisodeIndex >= newSource.episodes.count {
                        self.currentEpisodeIndex = 0
                    }
                    self.currentTime = resumeTime
                    if self.currentEpisodeIndex < newSource.episodes.count {
                        self.setupPlayer(urlString: newSource.episodes[self.currentEpisodeIndex])
                    }
                    self.isFavorited = PersistenceService.shared.isFavorited(source: newSource.source, id: newSource.id)
                }
            }
        }
    }

    func setSpeed(_ speed: Float) {
        playbackSpeed = speed
        if isPlaying {
            player?.rate = speed
        }
    }

    func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            player.rate = playbackSpeed
            isPlaying = true
        }
    }

    func seek(to seconds: Double) {
        guard seconds.isFinite else { return }
        let clampedSeconds = min(max(seconds, 0), max(totalDuration, 0))
        let seekTime = CMTime(seconds: clampedSeconds, preferredTimescale: 600)
        player?.seek(to: seekTime) { [weak self] _ in
            DispatchQueue.main.async {
                self?.currentTime = clampedSeconds
            }
        }
    }

    func toggleFavorite() {
        guard let source = currentSource else { return }
        if isFavorited {
            PersistenceService.shared.deleteFavorite(source: source.source, id: source.id)
        } else {
            let favorite = Favorite(
                sourceName: source.sourceName,
                totalEpisodes: source.episodes.count,
                title: source.title,
                year: source.year,
                cover: source.poster,
                saveTime: Date().timeIntervalSince1970 * 1000,
                searchTitle: searchTitle
            )
            PersistenceService.shared.saveFavorite(source: source.source, id: source.id, favorite: favorite)
        }
        isFavorited.toggle()
    }

    func saveProgress() {
        guard let source = currentSource else { return }
        let record = PlayRecord(
            title: source.title,
            sourceName: source.sourceName,
            cover: source.poster,
            year: source.year,
            index: currentEpisodeIndex + 1,
            totalEpisodes: source.episodes.count,
            playTime: currentTime,
            totalTime: totalDuration,
            saveTime: Date().timeIntervalSince1970 * 1000,
            searchTitle: searchTitle
        )
        PersistenceService.shared.savePlayRecord(source: source.source, id: source.id, record: record)
    }

    func startProgressTimer() {
        guard saveTimer == nil else { return }
        saveTimer = Timer.scheduledTimer(withTimeInterval: Constants.progressSaveInterval, repeats: true) { [weak self] _ in
            self?.updateCurrentTime()
            self?.saveProgress()
        }
    }

    func stopProgressTimer() {
        saveTimer?.invalidate()
        saveTimer = nil
    }

    func updateCurrentTime() {
        if let player = player {
            let time = CMTimeGetSeconds(player.currentTime())
            if time.isFinite {
                currentTime = max(time, 0)
            }
            if let duration = player.currentItem?.duration, CMTIME_IS_VALID(duration) {
                let seconds = CMTimeGetSeconds(duration)
                if seconds.isFinite && seconds > 0 {
                    totalDuration = seconds
                }
            }
        }
    }

    // MARK: - Private

    private func loadFromSource(source: String, id: String) {
        Task {
            do {
                print("[PlayVM] loadFromSource 开始请求 source=\(source), id=\(id)")
                let result = try await MacCMSAPIService.shared.fetchVideoDetail(
                    source: source, id: id, fallbackTitle: searchTitle.isEmpty ? nil : searchTitle
                )
                print("[PlayVM] loadFromSource 成功 episodes=\(result.episodes.count), sourceName=\(result.sourceName)")
                DispatchQueue.main.async {
                    self.currentSource = result
                    self.allSources = [result]
                    self.isLoading = false
                    self.startPlayback()
                }

                pendingSearchOtherTask = Task { [weak self] in
                    guard let self else { return }
                    await self.searchOtherSources(title: result.title, excludeSource: source, excludeId: id)
                }
                await pendingSearchOtherTask?.value
                pendingSearchOtherTask = nil

                let sources = await MainActor.run { self.allSources }
                await runSourcePreference(sources: sources)
            } catch {
                print("[PlayVM] loadFromSource 失败 error=\(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "加载影片详情失败: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    private func searchAndPlay(title searchQuery: String) {
        Task {
            print("[PlayVM] searchAndPlay 开始搜索 title=\(searchQuery)")
            var result = await SourceSearchService.shared.searchAllSourcesSimple(query: searchQuery)
            print("[PlayVM] searchAndPlay 结果数=\(result.results.count), failures=\(result.failures.count)")

            var matched = result.results.filter { videoTitle.matchesTitle($0.title) }
            print("[PlayVM] searchAndPlay 标题匹配后=\(matched.count)")

            if matched.isEmpty && !result.results.isEmpty {
                matched = result.results
            }

            if matched.isEmpty {
                let simplified = searchQuery
                    .replacingOccurrences(of: "[\\d]+$", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "[：:·\\-第季部集]", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                if !simplified.isEmpty && simplified != searchQuery {
                    print("[PlayVM] searchAndPlay 简化搜索词重试: \(simplified)")
                    let retry = await SourceSearchService.shared.searchAllSourcesSimple(query: simplified)
                    matched = retry.results
                    print("[PlayVM] searchAndPlay 简化重试结果=\(matched.count)")
                }
            }

            guard !matched.isEmpty else {
                print("[PlayVM] searchAndPlay 无结果")
                DispatchQueue.main.async {
                    self.errorMessage = "未找到可播放的源，请检查源配置"
                    self.isLoading = false
                }
                return
            }

            var targetDetail: SearchResult?
            if let cs = currentSource, !cs.source.isEmpty, !cs.id.isEmpty {
                targetDetail = matched.first(where: { $0.source == cs.source && $0.id == cs.id })
            }
            if targetDetail == nil {
                targetDetail = matched[0]
            }

            guard let first = targetDetail else {
                DispatchQueue.main.async {
                    self.errorMessage = "未找到可播放的源"
                    self.isLoading = false
                }
                return
            }

            print("[PlayVM] searchAndPlay 使用结果 source=\(first.sourceName), episodes=\(first.episodes.count)")

            DispatchQueue.main.async {
                self.currentSource = first
                self.allSources = matched
                self.isLoading = false
                self.errorMessage = nil
                self.startPlayback()
            }

            await runSourcePreference(sources: matched)
        }
    }

    private func startPlayback() {
        guard let source = currentSource,
              currentEpisodeIndex < source.episodes.count else {
            print("[PlayVM] startPlayback 失败: source=\(currentSource != nil), episodes=\(currentSource?.episodes.count ?? 0), index=\(currentEpisodeIndex)")
            DispatchQueue.main.async {
                self.errorMessage = "没有可播放的剧集"
                self.isLoading = false
            }
            return
        }

        let urlString = source.episodes[currentEpisodeIndex]
        print("[PlayVM] startPlayback episodeIndex=\(currentEpisodeIndex), url=\(urlString.prefix(120))...")
        setupPlayer(urlString: urlString)
    }

    func setupPlayer(urlString: String) {
        print("[PlayVM] setupPlayer 原始URL前200字符: \(urlString.prefix(200))")

        let resolvedURL: URL
        if let url = URL(string: urlString) {
            resolvedURL = url
            print("[PlayVM] URL直接解析成功 scheme=\(url.scheme ?? "nil"), host=\(url.host ?? "nil")")
        } else if let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
                  let url = URL(string: encoded) {
            resolvedURL = url
            print("[PlayVM] URL percent-encoding后解析成功 scheme=\(url.scheme ?? "nil"), host=\(url.host ?? "nil")")
        } else {
            print("[PlayVM] URL解析完全失败")
            DispatchQueue.main.async {
                self.tryNextSourceOrFallback()
            }
            return
        }

        stopProgressTimer()
        removeTimeObserver()
        removeItemObservers()

        errorMessage = nil
        let item = AVPlayerItem(url: resolvedURL)
        playerItem = item

        // 监听播放项状态
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemFailedToPlay),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: item
        )

        if player == nil {
            player = AVPlayer(playerItem: item)
            print("[PlayVM] 创建新AVPlayer")
        } else {
            player?.replaceCurrentItem(with: item)
            print("[PlayVM] 替换AVPlayer当前item")
        }

        player?.play()
        player?.rate = playbackSpeed
        isPlaying = true
        print("[PlayVM] 调用player.play(), rate=\(playbackSpeed)")

        // 恢复播放位置
        if currentTime > 0 {
            let seekTime = CMTime(seconds: currentTime, preferredTimescale: 600)
            player?.seek(to: seekTime)
            print("[PlayVM] 恢复到位置 \(currentTime)s")
        }

        addTimeObserver()
        startProgressTimer()
    }

    // KVO 监听播放状态
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status),
           let item = object as? AVPlayerItem {
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    print("[PlayVM] AVPlayerItem status = readyToPlay")
                case .failed:
                    let error = item.error
                    print("[PlayVM] AVPlayerItem status = FAILED, error=\(error?.localizedDescription ?? "nil")")
                    self.tryNextSourceOrFallback()
                case .unknown:
                    print("[PlayVM] AVPlayerItem status = unknown")
                @unknown default:
                    print("[PlayVM] AVPlayerItem status = unknown(\(item.status.rawValue))")
                }
            }
        }
    }

    private func tryNextSourceOrFallback() {
        guard let current = currentSource else {
            errorMessage = "播放加载失败"
            return
        }

        // 记录当前失败的源
        let failedKey = "\(current.source)+\(current.id)"
        failedSourceKeys.insert(failedKey)
        print("[PlayVM] 源失败: \(current.sourceName), 已失败源列表: \(failedSourceKeys)")

        // 查找下一个未失败过的源
        if let nextSource = allSources.first(where: {
            let key = "\($0.source)+\($0.id)"
            return !failedSourceKeys.contains(key) && !$0.episodes.isEmpty
        }) {
            print("[PlayVM] 自动切换到: \(nextSource.sourceName)")
            performSourceSwitch(to: nextSource, resumeTime: currentTime)
            return
        }

        // 没有可用的源了，等待后台搜索
        if let pendingTask = pendingSearchOtherTask {
            print("[PlayVM] 所有已知源均已失败，等待后台搜索完成...")
            isLoading = true
            Task { [weak self] in
                await pendingTask.value
                guard let self else { return }
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let nextSource = self.allSources.first(where: {
                        let key = "\($0.source)+\($0.id)"
                        return !self.failedSourceKeys.contains(key) && !$0.episodes.isEmpty
                    }) {
                        print("[PlayVM] 后台搜索完成，切换到: \(nextSource.sourceName)")
                        self.performSourceSwitch(to: nextSource, resumeTime: self.currentTime)
                    } else {
                        self.errorMessage = "播放加载失败: 所有源均已尝试"
                    }
                }
            }
            return
        }

        errorMessage = "播放加载失败: 所有源均已尝试"
    }

    @objc private func playerItemFailedToPlay(_ notification: Notification) {
        DispatchQueue.main.async {
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            print("[PlayVM] playerItemFailedToPlay error=\(error?.localizedDescription ?? "nil")")
        }
    }

    private func addTimeObserver() {
        guard let player else { return }
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            self?.updateCurrentTime()
            self?.isPlaying = player.timeControlStatus == .playing
        }
    }

    private func removeTimeObserver() {
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
    }

    private func removeItemObservers() {
        if let oldItem = playerItem {
            oldItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: oldItem)
        }
    }

    private func searchOtherSources(title searchQuery: String, excludeSource: String, excludeId: String) async {
        let result = await SourceSearchService.shared.searchAllSourcesSimple(query: searchQuery)

        let matched = result.results.filter { videoTitle.matchesTitle($0.title) }
        let otherSources = matched.filter { $0.source != excludeSource || $0.id != excludeId }

        DispatchQueue.main.async {
            var seen = Set<String>()
            var merged: [SearchResult] = []
            if let current = self.currentSource {
                let currentKey = "\(current.source)+\(current.id)"
                seen.insert(currentKey)
                merged.append(current)
            }
            for src in otherSources {
                let key = "\(src.source)+\(src.id)"
                if seen.insert(key).inserted {
                    merged.append(src)
                }
            }

            self.allSources = merged
            print("[PlayVM] searchOtherSources 合并后 allSources=\(merged.count), matched=\(matched.count)")
        }
    }

    private func runSourcePreference(sources: [SearchResult]) async {
        guard let result = await SourcePreferenceService.shared.preferBestSource(sources: sources) else { return }
        DispatchQueue.main.async {
            self.scoredSources = result.allScores

            let scoreMap: [String: Int] = Dictionary(
                uniqueKeysWithValues: result.allScores.map { ("\($0.source.source)+\($0.source.id)", $0.score) }
            )
            self.allSources = self.allSources.sorted {
                let scoreA = scoreMap["\($0.source)+\($0.id)"] ?? 0
                let scoreB = scoreMap["\($1.source)+\($1.id)"] ?? 0
                return scoreA > scoreB
            }

            if !self.isLoading,
               let current = self.currentSource,
               let best = result.allScores.first,
               best.source.source != current.source || best.source.id != current.id {
                let currentKey = "\(current.source)+\(current.id)"
                let currentScore = scoreMap[currentKey] ?? 0
                if best.score > currentScore {
                    self.shouldPromptBetterSource = true
                }
            }
        }
    }

    deinit {
        print("[PlayVM] deinit")
        pendingSearchOtherTask?.cancel()
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        NotificationCenter.default.removeObserver(self)
        saveProgress()
        stopProgressTimer()
        removeTimeObserver()
        player?.pause()
        player = nil
    }
}
