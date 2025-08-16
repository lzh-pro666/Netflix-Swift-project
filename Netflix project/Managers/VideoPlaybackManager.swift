import Foundation
import AVFoundation
import CachingPlayerItem

// MARK: - 视频播放管理器
class VideoPlaybackManager: NSObject {
    
    static let shared = VideoPlaybackManager()
    
    // MARK: - 属性
    private var player: AVPlayer?
    private var currentPlayerItem: CachingPlayerItem?
    private var preloadQueue: [(item: CachingPlayerItem, url: URL)] = []
    private let maxPreloadCount = 3
    
    // MARK: - 播放状态
    var isPlaying: Bool = false
    var currentTime: CMTime = .zero
    var duration: CMTime = .zero
    
    // MARK: - 回调
    var onPlaybackStateChanged: ((VideoPlaybackState) -> Void)?
    var onTimeUpdate: ((CMTime) -> Void)?
    var onPlaybackFinished: (() -> Void)?
    
    private override init() {
        super.init()
        setupPlayer()
    }
    
    // MARK: - 播放器设置
    private func setupPlayer() {
        player = AVPlayer()
        player?.automaticallyWaitsToMinimizeStalling = false
        
        // 添加时间观察者
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time
            self?.onTimeUpdate?(time)
        }
        
        // 添加播放状态观察者
        player?.addObserver(self, forKeyPath: "timeControlStatus", options: [.new, .old], context: nil)
    }
    
    // MARK: - 视频播放控制
    func playVideo(with url: URL) {
        // 检查缓存
        if let cachedItem = VideoCacheManager.shared.getCachedItem(for: url) {
            playPlayerItem(cachedItem)
            return
        }
        
        // 创建新的播放项
        let playerItem = CachingPlayerItem(url: url)
        playerItem.delegate = self
        
        // 缓存播放项
        VideoCacheManager.shared.cacheItem(playerItem, for: url)
        
        playPlayerItem(playerItem)
    }
    
    private func playPlayerItem(_ playerItem: CachingPlayerItem) {
        currentPlayerItem = playerItem
        player?.replaceCurrentItem(with: playerItem)
        player?.play()
        isPlaying = true
        
        onPlaybackStateChanged?(.playing)
    }
    
    func pauseVideo() {
        player?.pause()
        isPlaying = false
        onPlaybackStateChanged?(.paused)
    }
    
    func resumeVideo() {
        player?.play()
        isPlaying = true
        onPlaybackStateChanged?(.playing)
    }
    
    func stopVideo() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        onPlaybackStateChanged?(.idle)
    }
    
    func seekToTime(_ time: CMTime) {
        player?.seek(to: time) { [weak self] finished in
            if finished {
                self?.onTimeUpdate?(time)
            }
        }
    }
    
    // MARK: - 预加载管理
    func preloadVideo(with url: URL) {
        // 检查是否已经在预加载队列中
        if preloadQueue.contains(where: { $0.url.absoluteString == url.absoluteString }) {
            return
        }
        
        // 检查缓存
        if VideoCacheManager.shared.getCachedItem(for: url) != nil {
            return
        }
        
        // 创建预加载项
        let preloadItem = CachingPlayerItem(url: url)
        preloadItem.delegate = self
        
        // 添加到预加载队列，同时保存 URL
        preloadQueue.append((item: preloadItem, url: url))
        
        // 限制预加载数量
        if preloadQueue.count > maxPreloadCount {
            let removedItem = preloadQueue.removeFirst()
            removedItem.item.delegate = nil
        }
        
        print("开始预加载视频: \(url.lastPathComponent)")
    }
    
    func cancelPreload(for url: URL) {
        preloadQueue.removeAll { $0.url.absoluteString == url.absoluteString }
    }
    
    func clearPreloadQueue() {
        preloadQueue.removeAll()
    }
    
    // MARK: - 网络状态处理
    func handleNetworkStatusChange(isReachable: Bool) {
        if isReachable {
            // 网络恢复，可以继续预加载
            print("网络恢复，继续预加载")
        } else {
            // 网络断开，暂停预加载
            print("网络断开，暂停预加载")
            clearPreloadQueue()
        }
    }
    
    // MARK: - 内存管理
    func handleMemoryWarning() {
        // 清理预加载队列
        clearPreloadQueue()
        
        // 清理缓存
        VideoCacheManager.shared.clearCache()
        
        print("内存警告，清理视频缓存")
    }
    
    // MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "timeControlStatus" {
            if let player = object as? AVPlayer {
                switch player.timeControlStatus {
                case .waitingToPlayAtSpecifiedRate:
                    onPlaybackStateChanged?(.loading)
                case .playing:
                    onPlaybackStateChanged?(.playing)
                case .paused:
                    onPlaybackStateChanged?(.paused)
                @unknown default:
                    break
                }
            }
        }
    }
    
    // MARK: - 清理
    deinit {
        player?.removeObserver(self, forKeyPath: "timeControlStatus")
        clearPreloadQueue()
    }
}

// MARK: - CachingPlayerItemDelegate
extension VideoPlaybackManager: CachingPlayerItemDelegate {
    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) {
        print("视频下载完成")
        
        // 从预加载队列中移除对应的项
        // 由于无法直接访问 playerItem.url，我们需要通过其他方式识别
        // 这里简化处理，实际项目中可能需要更复杂的标识机制
        if preloadQueue.count > 0 {
            preloadQueue.removeFirst()
        }
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, didFailToDownloadDataForRequestedURL url: URL, withError error: Error) {
        print("视频下载失败: \(url.lastPathComponent), 错误: \(error.localizedDescription)")
        
        // 从预加载队列中移除对应的项
        preloadQueue.removeAll { $0.url.absoluteString == url.absoluteString }
        
        // 通知播放状态变化
        onPlaybackStateChanged?(.error(error.localizedDescription))
    }
}
