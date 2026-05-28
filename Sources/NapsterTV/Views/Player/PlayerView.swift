import SwiftUI
import AVFoundation
import AppKit

struct PlayerView: View {
    let source: String
    let id: String
    let title: String
    let year: String
    let searchTitle: String
    let prefer: Bool

    @StateObject private var viewModel = PlayViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingEpisodePicker = false
    @State private var showingSourcePicker = false
    @State private var isSeeking = false
    @State private var seekValue: Double = 0
    @State private var showControls = true
    @State private var autoHideTask: Task<Void, Never>?
    @State private var showSpeedPicker = false
    @State private var isFullScreen = false

    var body: some View {
        VStack(spacing: 0) {
            // 视频播放器
            playerSurface
                .aspectRatio(16/9, contentMode: .fit)
                .frame(maxWidth: .infinity)

            // 错误提示
            if let error = viewModel.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                    Text(error)
                        .font(.system(size: 13))
                }
                .foregroundColor(.themeError)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.08))
            }

            // 视频信息和控制
            ScrollView {
                VStack(spacing: 8) {
                    videoInfoSection
                    controlBar
                    if let desc = viewModel.currentSource?.desc, !desc.isEmpty {
                        descriptionSection(desc)
                    }
                }
                .padding(.bottom, 16)
            }
            .background(Color.themeBackground)
        }
        .background(Color.themePlayerBackground)
        .navigationTitle(viewModel.videoTitle)
        .sheet(isPresented: $showingEpisodePicker) {
            episodePickerSheet
        }
        .sheet(isPresented: $showingSourcePicker) {
            sourcePickerSheet
        }
        .alert("发现更好的来源", isPresented: $viewModel.shouldPromptBetterSource) {
            Button("切换") {
                viewModel.shouldPromptBetterSource = false
                if let best = viewModel.scoredSources.first {
                    viewModel.switchSource(to: best.source)
                }
            }
            Button("继续观看", role: .cancel) {
                viewModel.shouldPromptBetterSource = false
            }
        } message: {
            if let best = viewModel.scoredSources.first {
                Text("\(best.source.sourceName) 评分 \(best.score)，当前源可能质量更好")
            }
        }
        .alert("播放错误", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("返回") {
                dismiss()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .onAppear {
            viewModel.initialize(source: source, id: id, title: title, year: year, searchTitle: searchTitle, prefer: prefer)
        }
        .onDisappear {
            viewModel.player?.pause()
            viewModel.saveProgress()
            viewModel.stopProgressTimer()
        }
        .onChange(of: viewModel.currentTime) { _, newValue in
            if !isSeeking {
                seekValue = newValue
            }
        }
        // macOS 键盘快捷键
        .onKeyPress(.space) {
            viewModel.togglePlayPause()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            viewModel.seek(to: max(viewModel.currentTime - 10, 0))
            return .handled
        }
        .onKeyPress(.rightArrow) {
            viewModel.seek(to: min(viewModel.currentTime + 10, viewModel.totalDuration))
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "fF")) { _ in
            toggleFullScreen()
            return .handled
        }
        .onKeyPress(.escape) {
            if isFullScreen {
                exitFullScreen()
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - 全屏

    private func toggleFullScreen() {
        if isFullScreen {
            exitFullScreen()
        } else {
            enterFullScreen()
        }
    }

    private func enterFullScreen() {
        guard let player = viewModel.player else { return }
        isFullScreen = true

        let fullScreenView = FullScreenPlayerView(
            player: player,
            viewModel: viewModel,
            onExit: { exitFullScreen() }
        )
        let hostingView = NSHostingView(rootView: fullScreenView)

        guard let screen = NSScreen.main else { return }
        let window = FullScreenWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.contentView = hostingView
        window.level = .statusBar
        window.isOpaque = true
        window.backgroundColor = .black
        window.collectionBehavior = [.fullScreenAuxiliary]
        window.makeKeyAndOrderFront(nil)

        FullScreenWindowManager.shared.window = window
        FullScreenWindowManager.shared.onExit = { [self] in
            self.isFullScreen = false
        }
    }

    private func exitFullScreen() {
        isFullScreen = false
        FullScreenWindowManager.shared.close()
    }

    // MARK: - 播放器

    private var playerSurface: some View {
        ZStack {
            Color.black
            if let player = viewModel.player {
                MacAVPlayerView(player: player)
            }

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
                    .colorScheme(.dark)
            }

            // 点击区域
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    toggleFullScreen()
                }
                .onTapGesture(count: 1) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showControls.toggle()
                    }
                    if showControls {
                        resetAutoHideTimer()
                    }
                }

            if showControls {
                playerControls
                    .transition(.opacity)
            }

            // 倍速选择浮层
            if showSpeedPicker {
                Color.black.opacity(0.01)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSpeedPicker = false
                        }
                    }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 0) {
                            ForEach(Array(Constants.playbackSpeeds.enumerated()), id: \.offset) { _, speed in
                                Button {
                                    viewModel.setSpeed(speed)
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showSpeedPicker = false
                                    }
                                    resetAutoHideTimer()
                                } label: {
                                    HStack {
                                        Text("\(speed.description)x")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        if speed == viewModel.playbackSpeed {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.themePrimary)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(speed == viewModel.playbackSpeed ? Color.white.opacity(0.15) : Color.clear)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(width: 160)
                        .background(Color(white: 0.15))
                        .cornerRadius(12)
                        .padding(.trailing, 50)
                    }
                    .padding(.bottom, 70)
                }
                .transition(.opacity)
            }
        }
        .clipped()
        .background(Color.black)
        .onContinuousHover { phase in
            switch phase {
            case .active:
                if !showControls {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showControls = true
                    }
                }
                resetAutoHideTimer()
            case .ended:
                break
            }
        }
        .onAppear { resetAutoHideTimer() }
        .onDisappear { autoHideTask?.cancel() }
    }

    private func resetAutoHideTimer() {
        autoHideTask?.cancel()
        autoHideTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                showControls = false
            }
        }
    }

    private var playerControls: some View {
        VStack(spacing: 0) {
            HStack {
                Text(viewModel.videoTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Spacer()

            Button {
                viewModel.togglePlayPause()
                resetAutoHideTimer()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            playerProgressBar
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .background(
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)
                )
        }
    }

    private var playerProgressBar: some View {
        let duration = max(viewModel.totalDuration, 0)
        let sliderRange = 0...max(duration, 1)
        let displayTime = isSeeking ? seekValue : viewModel.currentTime

        return VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { min(max(isSeeking ? seekValue : viewModel.currentTime, 0), max(duration, 1)) },
                    set: { seekValue = $0 }
                ),
                in: sliderRange,
                onEditingChanged: { editing in
                    isSeeking = editing
                    if editing {
                        autoHideTask?.cancel()
                    } else {
                        viewModel.seek(to: seekValue)
                        resetAutoHideTimer()
                    }
                }
            )
            .tint(.themePrimary)

            HStack(spacing: 8) {
                Button {
                    viewModel.togglePlayPause()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)

                Text("\(formatTime(displayTime)) / \(formatTime(duration))")
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.92))

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSpeedPicker.toggle()
                    }
                } label: {
                    Text(viewModel.playbackSpeed == 1.0 ? "倍速" : "\(viewModel.playbackSpeed.description)x")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 30)
                }
                .buttonStyle(.plain)

                Button {
                    toggleFullScreen()
                    resetAutoHideTimer()
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .help("全屏 (F)")
            }
        }
    }

    // MARK: - 视频信息

    private var videoInfoSection: some View {
        VStack(spacing: 8) {
            // 标题行
            HStack {
                Text(viewModel.videoTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.themeText)
                    .lineLimit(1)

                Spacer()

                Button {
                    viewModel.toggleFavorite()
                } label: {
                    Text(viewModel.isFavorited ? "已收藏" : "收藏")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(viewModel.isFavorited ? .themePrimary : .themeTextSecondary)
                }
                .buttonStyle(.plain)
            }

            // 元信息行
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if !viewModel.videoYear.isEmpty && viewModel.videoYear != "unknown" {
                        metaBadge(viewModel.videoYear)
                    }
                    if let typeName = viewModel.currentSource?.typeName, !typeName.isEmpty {
                        metaBadge(typeName)
                    }
                    if let sourceName = viewModel.currentSource?.sourceName {
                        metaBadge(sourceName)
                    }
                    metaBadge("第\(viewModel.currentEpisodeIndex + 1)集")
                }
            }
        }
        .padding(16)
        .background(Color.themeWhite)
    }

    // MARK: - 控制栏

    private var controlBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if let source = viewModel.currentSource, source.episodes.count > 1 {
                    controlButton("选集") { showingEpisodePicker = true }
                    controlButton("换源") { showingSourcePicker = true }
                } else if viewModel.allSources.count > 1 {
                    controlButton("换源") { showingSourcePicker = true }
                }

                if viewModel.currentEpisodeIndex > 0,
                   let source = viewModel.currentSource, source.episodes.count > 1 {
                    controlButton("上一集") {
                        viewModel.playEpisode(index: viewModel.currentEpisodeIndex - 1)
                    }
                }

                if let source = viewModel.currentSource,
                   viewModel.currentEpisodeIndex < source.episodes.count - 1 {
                    controlButton("下一集") {
                        viewModel.playEpisode(index: viewModel.currentEpisodeIndex + 1)
                    }
                }
            }
            .padding(16)
        }
        .background(Color.themeWhite)
    }

    private func controlButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.themeText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.themeBackground)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 简介

    private func descriptionSection(_ desc: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("简介")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.themeText)
            Text(desc)
                .font(.system(size: 14))
                .foregroundColor(.themeTextSecondary)
        }
        .padding(16)
        .background(Color.themeWhite)
    }

    // MARK: - 选集 Sheet

    private var episodePickerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("选集 (\(viewModel.currentSource?.episodes.count ?? 0))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeText)
                Spacer()
                Button("完成") { showingEpisodePicker = false }
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(16)

            ScrollView {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 8)
                if let source = viewModel.currentSource {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(0..<source.episodes.count, id: \.self) { index in
                            Button {
                                viewModel.playEpisode(index: index)
                                showingEpisodePicker = false
                            } label: {
                                Text(index < source.episodesTitles.count ? source.episodesTitles[index] : "第\(index + 1)集")
                                    .font(.system(size: 13))
                                    .foregroundColor(index == viewModel.currentEpisodeIndex ? .white : .themeText)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(index == viewModel.currentEpisodeIndex ? Color.themePrimary : Color.themeCard)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(width: 500, height: 400)
        .background(Color.themeBackground)
    }

    // MARK: - 换源 Sheet

    private var sourcePickerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("选择来源")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button("完成") { showingSourcePicker = false }
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(16)

            List {
                ForEach(viewModel.allSources) { src in
                    Button {
                        viewModel.switchSource(to: src)
                        showingSourcePicker = false
                    } label: {
                        HStack {
                            Text(src.sourceName)
                                .foregroundColor(.themeText)
                            Spacer()
                            Text("\(src.episodes.count) 集")
                                .foregroundColor(.themeTextSecondary)

                            // 评分徽章
                            if let scored = viewModel.scoredSources.first(where: { $0.source.id == src.id }) {
                                Text("\(scored.score)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(scored.score >= 70 ? .themeSuccess : (scored.score >= 40 ? .themeWarning : .themeError))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(scored.score >= 70 ? Color.green.opacity(0.1) : (scored.score >= 40 ? Color.orange.opacity(0.1) : Color.red.opacity(0.1)))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 450, height: 350)
    }

    private func metaBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.themePrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.themePrimaryLight)
            .cornerRadius(8)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds > 0 else { return "00:00" }
        let totalSeconds = Int(seconds.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

// AVPlayer NSViewRepresentable 封装 (macOS)
struct MacAVPlayerView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor

        let playerLayer = AVPlayerLayer()
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        view.layer?.addSublayer(playerLayer)

        context.coordinator.playerLayer = playerLayer
        context.coordinator.parentView = view

        print("[MacAVPlayerView] makeNSView player=\(player), bounds=\(view.bounds)")

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.playerLayer?.player = player
            context.coordinator.playerLayer?.frame = nsView.bounds
            print("[MacAVPlayerView] updateNSView bounds=\(nsView.bounds), playerItem=\(player.currentItem != nil)")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var playerLayer: AVPlayerLayer?
        var parentView: NSView?

        override init() {
            super.init()
            // 监听窗口大小变化
            NotificationCenter.default.addObserver(
                self, selector: #selector(layoutChanged),
                name: NSView.frameDidChangeNotification, object: nil
            )
        }

        @objc func layoutChanged(_ notification: Notification) {
            DispatchQueue.main.async { [weak self] in
                guard let view = self?.parentView else { return }
                self?.playerLayer?.frame = view.bounds
            }
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

// MARK: - 全屏播放器窗口

class FullScreenWindowManager {
    static let shared = FullScreenWindowManager()
    var window: NSWindow?
    var onExit: (() -> Void)?

    func close() {
        window?.orderOut(nil)
        window = nil
        onExit?()
        onExit = nil
    }
}

class FullScreenWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        // ESC 键退出全屏
        if event.keyCode == 53 {
            FullScreenWindowManager.shared.close()
            return
        }
        super.keyDown(with: event)
    }
}

struct FullScreenPlayerView: View {
    let player: AVPlayer
    @ObservedObject var viewModel: PlayViewModel
    let onExit: () -> Void

    @State private var showControls = true
    @State private var autoHideTask: Task<Void, Never>?
    @State private var isSeeking = false
    @State private var seekValue: Double = 0
    @State private var showSpeedPicker = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            MacAVPlayerView(player: player)
                .ignoresSafeArea()

            // 点击区域
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    onExit()
                }
                .onTapGesture(count: 1) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showControls.toggle()
                    }
                    if showControls { resetAutoHideTimer() }
                }

            if showControls {
                fullScreenControls
                    .transition(.opacity)
            }

            // 倍速选择浮层
            if showSpeedPicker {
                Color.black.opacity(0.01)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSpeedPicker = false
                        }
                    }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 0) {
                            ForEach(Array(Constants.playbackSpeeds.enumerated()), id: \.offset) { _, speed in
                                Button {
                                    viewModel.setSpeed(speed)
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showSpeedPicker = false
                                    }
                                    resetAutoHideTimer()
                                } label: {
                                    HStack {
                                        Text("\(speed.description)x")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        if speed == viewModel.playbackSpeed {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.themePrimary)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(speed == viewModel.playbackSpeed ? Color.white.opacity(0.15) : Color.clear)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(width: 160)
                        .background(Color(white: 0.15))
                        .cornerRadius(12)
                        .padding(.trailing, 50)
                    }
                    .padding(.bottom, 80)
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .onContinuousHover { phase in
            switch phase {
            case .active:
                if !showControls {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showControls = true
                    }
                }
                resetAutoHideTimer()
            case .ended:
                break
            }
        }
        .onAppear { resetAutoHideTimer() }
        .onDisappear { autoHideTask?.cancel() }
        .onKeyPress(.escape) {
            onExit()
            return .handled
        }
        .onKeyPress(.space) {
            viewModel.togglePlayPause()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            viewModel.seek(to: max(viewModel.currentTime - 10, 0))
            return .handled
        }
        .onKeyPress(.rightArrow) {
            viewModel.seek(to: min(viewModel.currentTime + 10, viewModel.totalDuration))
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "fF")) { _ in
            onExit()
            return .handled
        }
        .onChange(of: viewModel.currentTime) { _, newValue in
            if !isSeeking { seekValue = newValue }
        }
    }

    private var fullScreenControls: some View {
        VStack(spacing: 0) {
            // 顶部：标题 + 退出按钮
            HStack {
                Button {
                    onExit()
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Text(viewModel.videoTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer()

            // 中间播放/暂停
            Button {
                viewModel.togglePlayPause()
                resetAutoHideTimer()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            // 底部进度条
            fullScreenProgressBar
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .background(
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)
                )
        }
    }

    private var fullScreenProgressBar: some View {
        let duration = max(viewModel.totalDuration, 0)
        let sliderRange = 0...max(duration, 1)
        let displayTime = isSeeking ? seekValue : viewModel.currentTime

        return VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { min(max(isSeeking ? seekValue : viewModel.currentTime, 0), max(duration, 1)) },
                    set: { seekValue = $0 }
                ),
                in: sliderRange,
                onEditingChanged: { editing in
                    isSeeking = editing
                    if editing {
                        autoHideTask?.cancel()
                    } else {
                        viewModel.seek(to: seekValue)
                        resetAutoHideTimer()
                    }
                }
            )
            .tint(.themePrimary)

            HStack(spacing: 8) {
                Button {
                    viewModel.togglePlayPause()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)

                Text("\(formatTime(displayTime)) / \(formatTime(duration))")
                    .font(.system(size: 13, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.92))

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSpeedPicker.toggle()
                    }
                } label: {
                    Text(viewModel.playbackSpeed == 1.0 ? "倍速" : "\(viewModel.playbackSpeed.description)x")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 30)
                }
                .buttonStyle(.plain)

                Button {
                    onExit()
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .help("退出全屏 (Esc)")
            }
        }
    }

    private func resetAutoHideTimer() {
        autoHideTask?.cancel()
        autoHideTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                showControls = false
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds > 0 else { return "00:00" }
        let totalSeconds = Int(seconds.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}
