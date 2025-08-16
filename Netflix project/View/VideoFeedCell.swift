import UIKit
import AsyncDisplayKit
import IGListKit
import AVFoundation

// MARK: - 视频 Feed 单元格
class VideoFeedCell: ASCellNode {
    
    // MARK: - UI 组件
    private let videoNode = ASVideoNode()
    private let titleNode = ASTextNode()
    private let authorNode = ASTextNode()
    private let descriptionNode = ASTextNode()
    private let likeButtonNode = ASButtonNode()
    private let shareButtonNode = ASButtonNode()
    private let commentButtonNode = ASButtonNode()
    private let loadingIndicatorNode = ASDisplayNode()
    private let progressBarNode = ProgressNode() // 自绘进度条
    
    // MARK: - 数据
    private var videoModel: VideoFeedModel?
    private var playbackState: VideoPlaybackState = .idle
    private var duration: CMTime = .zero
    private var bottomContentInset: CGFloat = 0
    private var isDraggingProgress: Bool = false
    private var wasPlayingBeforeDrag: Bool = false
    private var isMediaReady: Bool = false
    private var playerItemObserver: NSKeyValueObservation?
    private var timeObserver: Any?
    private var timeObserverSetupAttempts = 0
    
    // 使用播放器池
    private var currentPlayerItem: AVPlayerItem?
    private var cachedScreenSize = CGSize(width: 375, height: 812) // fallback size
    
    // MARK: - 初始化
    init(videoModel: VideoFeedModel, bottomContentInset: CGFloat) {
        self.videoModel = videoModel
        self.bottomContentInset = bottomContentInset
        super.init()
        automaticallyManagesSubnodes = false
        
        // 缓存屏幕尺寸（此时在主线程）
        if Thread.isMainThread {
            cachedScreenSize = UIScreen.main.bounds.size
        }
        
        setupUI()
    }
    
    deinit {
        cleanupObservers()
    }
    
    // MARK: - UI 设置
    private func setupUI() {
        // 视频节点设置
        videoNode.backgroundColor = .black
        videoNode.isOpaque = true
        videoNode.shouldAutoplay = false
        videoNode.shouldAutorepeat = true
        videoNode.gravity = AVLayerVideoGravity.resizeAspect.rawValue
        
        // 文本内容
        if let model = videoModel {
            titleNode.attributedText = NSAttributedString(
                string: model.title,
                attributes: [
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: UIColor.systemRed
                ]
            )
            authorNode.attributedText = NSAttributedString(
                string: model.author,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.systemOrange
                ]
            )
            descriptionNode.attributedText = NSAttributedString(
                string: model.description,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.systemIndigo
                ]
            )
        }
        
        // 按钮设置
        likeButtonNode.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButtonNode.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.systemPink)
        shareButtonNode.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButtonNode.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.systemBlue)
        commentButtonNode.setImage(UIImage(systemName: "message"), for: .normal)
        commentButtonNode.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.systemTeal)
        
        // 加载指示器
        loadingIndicatorNode.backgroundColor = .clear
        
        // 添加所有子节点
        addSubnode(videoNode)
        addSubnode(titleNode)
        addSubnode(authorNode)
        addSubnode(descriptionNode)
        addSubnode(likeButtonNode)
        addSubnode(shareButtonNode)
        addSubnode(commentButtonNode)
        addSubnode(loadingIndicatorNode)
        addSubnode(progressBarNode)
    }
    
    // MARK: - 节点加载完成
    override func didLoad() {
        super.didLoad()
        // 在主线程刷新缓存的屏幕尺寸
        cachedScreenSize = UIScreen.main.bounds.size
        
        // 确保播放器图层背景为黑色，避免闪烁或不一致
        videoNode.playerLayer?.backgroundColor = UIColor.black.cgColor
        
        setupActions()
        setupVideo()
        setupProgressBarCallbacks()
    }

    // MARK: - 设置ProgressNode回调
    private func setupProgressBarCallbacks() {
        progressBarNode.onDragBegan = { [weak self] in
            guard let self = self else { return }
            if case .playing = self.playbackState { self.wasPlayingBeforeDrag = true } else { self.wasPlayingBeforeDrag = false }
            self.isDraggingProgress = true
            self.videoNode.pause()
            self.playbackState = .paused
        }
        progressBarNode.onProgressChanged = { [weak self] value in
            guard let self = self, self.isMediaReady, (self.duration.isValid && !self.duration.isIndefinite && self.duration.seconds.isFinite) else { return }
            let targetSeconds = Double(value) * self.duration.seconds
            let target = CMTime(seconds: targetSeconds, preferredTimescale: 600)
            self.currentPlayerItem?.cancelPendingSeeks()
            self.videoNode.player?.seek(to: target)
            self.updateProgressUI(progress: Double(value))
        }
        progressBarNode.onDragEnded = { [weak self] value in
            guard let self = self else { return }
            self.isDraggingProgress = false
            self.updateProgressUI(progress: Double(value))
            if self.wasPlayingBeforeDrag {
                self.videoNode.play()
                self.playbackState = .playing
            }
        }
    }
    
    private func setupVideo() {
        guard let model = videoModel else { return }
        
        // 重置状态
        resetVideoState()
        
        if let path = model.localVideoPath {
            let url = URL(fileURLWithPath: path)
            
            // 直接设置ASVideoNode的assetURL，让它内部管理播放器
            videoNode.assetURL = url
            
            // 监听播放器状态变化 (使用ASVideoNode内部的player)
            DispatchQueue.main.async { [weak self] in
                self?.observePlayerItemStatus()
            }
            
            // 添加进度观察者到ASVideoNode的player
            addPeriodicTimeObserver()
        }
    }
    
    private func observePlayerItemStatus() {
        // 使用ASVideoNode内部的currentItem
        guard let item = videoNode.player?.currentItem else {
            // 如果当前还没有生成内部的playerItem，稍后重试
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.observePlayerItemStatus()
            }
            return
        }
        
        // 保存引用，便于layout等处读取时长
        currentPlayerItem = item
        
        // 清理旧观察者，避免重复观察
        playerItemObserver?.invalidate()
        playerItemObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if item.status == .readyToPlay,
                   (item.duration.isValid && !item.duration.isIndefinite && item.duration.seconds.isFinite),
                   item.duration.seconds > 0 {
                    self.isMediaReady = true
                    self.duration = item.duration
                    
                    // 启用进度条
                    self.progressBarNode.isUserInteractionEnabled = true
                    
                    // 同步初始进度
                    let currentTime = self.videoNode.player?.currentTime().seconds ?? 0
                    let progress = currentTime / item.duration.seconds
                    self.updateProgressUI(progress: progress)
                    
                    // 确保进度观察者已添加（避免之前因player未生成导致未能添加）
                    self.addPeriodicTimeObserver()
                    
                    print("VideoFeedCell: 媒体准备就绪 - ID: \(self.videoModel?.id ?? "unknown")")
                } else {
                    self.isMediaReady = false
                    self.progressBarNode.isUserInteractionEnabled = false
                    print("VideoFeedCell: 媒体未就绪 - ID: \(self.videoModel?.id ?? "unknown")")
                }
            }
        }
    }
    
    private func addPeriodicTimeObserver() {
        // 清理之前的观察者
        if let observer = timeObserver {
            videoNode.player?.removeTimeObserver(observer)
        }
        
        // 如果此时还没有 player，稍后重试，避免丢失观察者
        guard let player = videoNode.player else {
            if timeObserverSetupAttempts < 40 { // 最多重试 ~4s（40 * 0.1s）
                timeObserverSetupAttempts += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.addPeriodicTimeObserver()
                }
            }
            return
        }
        
        // 重置重试计数
        timeObserverSetupAttempts = 0
        
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self = self,
                  let duration = self.videoNode.player?.currentItem?.duration,
                  (duration.isValid && !duration.isIndefinite && duration.seconds.isFinite),
                  duration.seconds > 0 else { return }
            
            self.duration = duration
            let progress = time.seconds / duration.seconds
            
            // 只在非拖动状态更新 UI
            if !self.isDraggingProgress {
                self.updateProgressUI(progress: progress)
            }
        }
    }
    
    private func updateProgressUI(progress: Double) {
        // 同步 ProgressNode 位置
        if !isDraggingProgress {
            progressBarNode.setProgress(CGFloat(progress), animated: false)
        }
    }
    
    // MARK: - 清理和重置方法
    private func resetVideoState() {
        isMediaReady = false
        isDraggingProgress = false
        wasPlayingBeforeDrag = false
        
        // 重置播放器到开始位置
        if currentPlayerItem != nil {
            videoNode.player?.seek(to: .zero) { _ in }
        }
        
        // 重置 ProgressNode
        progressBarNode.setProgress(0.0, animated: false)
        progressBarNode.isUserInteractionEnabled = false
        
        // 清理观察者
        cleanupObservers()
        
        print("VideoFeedCell: 视频状态重置 - ID: \(videoModel?.id ?? "unknown")")
    }
    
    private func cleanupObservers() {
        playerItemObserver?.invalidate()
        playerItemObserver = nil
        
        // 移除ASVideoNode播放器的时间观察者
        if let observer = timeObserver {
            videoNode.player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        // 重置重试计数
        timeObserverSetupAttempts = 0
    }
    
    // MARK: - 动作事件
    private func setupActions() {
        likeButtonNode.addTarget(self, action: #selector(likeButtonTapped), forControlEvents: .touchUpInside)
        shareButtonNode.addTarget(self, action: #selector(shareButtonTapped), forControlEvents: .touchUpInside)
        commentButtonNode.addTarget(self, action: #selector(commentButtonTapped), forControlEvents: .touchUpInside)
        
        // 视频点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(videoTapped))
        videoNode.view.addGestureRecognizer(tapGesture)
        
        // 视频长按手势 - 支持倍数播放
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(videoLongPressed(_:)))
        longPressGesture.minimumPressDuration = 0.5
        videoNode.view.addGestureRecognizer(longPressGesture)
    }
    
    @objc private func likeButtonTapped() { print("点赞") }
    @objc private func shareButtonTapped() { print("分享") }
    @objc private func commentButtonTapped() { print("评论") }
    
    @objc private func videoTapped() {
        switch playbackState {
        case .playing:
            videoNode.pause()
            playbackState = .paused
        case .paused, .idle:
            videoNode.play()
            playbackState = .playing
        default:
            break
        }
    }
    
    @objc private func videoLongPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            print("长按开始 - 设置2倍速播放")
            videoNode.player?.rate = 2.0
        case .ended, .cancelled:
            print("长按结束 - 恢复正常播放速度")
            videoNode.player?.rate = 1.0
        default:
            break
        }
    }
    
    // MARK: - 布局
    override func layout() {
        super.layout()
        
        // 同步当前播放进度到 UI
        if currentPlayerItem != nil,
           let item = currentPlayerItem,
           (item.duration.isValid && !item.duration.isIndefinite && item.duration.seconds.isFinite),
           item.duration.seconds > 0 {
            let currentTime = videoNode.player?.currentTime().seconds ?? 0
            let progress = currentTime / item.duration.seconds
            updateProgressUI(progress: progress)
        }
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let maxHeight = constrainedSize.max.height
        let maxWidth = constrainedSize.max.width
        
        // 使用缓存的屏幕尺寸而非直接访问UIScreen.main.bounds
        let fallbackHeight = cachedScreenSize.height
        let fallbackWidth = cachedScreenSize.width
        
        let safeHeight = maxHeight.isFinite ? maxHeight : fallbackHeight
        let safeWidth = maxWidth.isFinite ? maxWidth : fallbackWidth
        
        let clampedHeight = max(100, min(safeHeight, 2000))
        let clampedWidth = max(100, min(safeWidth, 1000))
        
        let videoHeight = clampedHeight
        
        // 视频节点背景为黑色，未显示区域显示为黑色
        videoNode.backgroundColor = .black
        videoNode.isOpaque = true
        // 视频按原始比例显示（不拉伸填充）
        videoNode.gravity = AVLayerVideoGravity.resizeAspect.rawValue
        // 同步图层背景为黑色（可选，确保底色一致）
        videoNode.playerLayer?.backgroundColor = UIColor.black.cgColor
        
        // 底部避让（TabBar + 安全区）
        let bottomInset = bottomContentInset
        
        // 右侧按钮
        let rightButtonsStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 20,
            justifyContent: .center,
            alignItems: .center,
            children: [likeButtonNode, commentButtonNode, shareButtonNode]
        )
        rightButtonsStack.style.preferredSize = CGSize(width: 60, height: 200)
        let buttonX = max(0, clampedWidth - 70)
        let buttonY = max(0, videoHeight - bottomInset - 250)
        rightButtonsStack.style.layoutPosition = CGPoint(x: buttonX, y: buttonY)
        
        // 标题/作者/描述
        let infoStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 8,
            justifyContent: .start,
            alignItems: .start,
            children: [titleNode, authorNode, descriptionNode]
        )
        infoStack.style.preferredSize = CGSize(width: max(80, clampedWidth - 120), height: 80)
        let infoY = max(0, videoHeight - bottomInset - 120)
        infoStack.style.layoutPosition = CGPoint(x: 16, y: infoY)
        
        // 进度条
        let progressHeight: CGFloat = 30
        progressBarNode.style.preferredSize = CGSize(width: clampedWidth - 32, height: progressHeight)
        let progressBottomMargin: CGFloat = 12
        let progressPosY = max(0, videoHeight - bottomInset - progressHeight - progressBottomMargin)
        progressBarNode.style.layoutPosition = CGPoint(x: 16, y: progressPosY)
        
        let absoluteLayout = ASAbsoluteLayoutSpec(
            sizing: .default,
            children: [videoNode, rightButtonsStack, infoStack, progressBarNode]
        )
        return absoluteLayout
    }
    
    // MARK: - 生命周期
    override func didEnterVisibleState() {
        super.didEnterVisibleState()
        
        // 重置到开始状态并开始播放
        resetVideoState()
        setupVideo()
        
        if case .idle = playbackState {
            videoNode.play()
            playbackState = .playing
        }
        
        print("VideoFeedCell: 进入可见状态 - ID: \(videoModel?.id ?? "unknown")")
    }
    
    override func didExitVisibleState() {
        super.didExitVisibleState()
        
        if case .playing = playbackState {
            videoNode.pause()
            playbackState = .paused
        }
        
        // 清理所有观察者
        cleanupObservers()
        
        // 停止并解绑视频源（ASVideoNode.player为只读，清空assetURL即可）
        videoNode.pause()
        videoNode.assetURL = nil
        currentPlayerItem = nil
        
        print("VideoFeedCell: 退出可见状态 - ID: \(videoModel?.id ?? "unknown")")
    }
}
