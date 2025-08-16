import Foundation
import AVFoundation
import AsyncDisplayKit

// MARK: - 视频播放器池管理器
/// 全局管理最多2个AVPlayer实例：1个主播放器(active)，1个预热播放器(warmup)
/// 统一管理timeObserver和播放器绑定，避免多播放器竞争和资源浪费
class VideoPlayerPool: NSObject {
    
    // MARK: - 单例
    static let shared = VideoPlayerPool()
    
    // MARK: - 属性
    private let mainPlayer = AVPlayer()      // 主播放器，用于当前可见Cell
    private let warmupPlayer = AVPlayer()    // 预热播放器，用于预加载下一个视频
    
    // 当前激活状态
    private var activeItemToken: UUID?       // 当前绑定item的代际token，防止竞态
    private var timeObserver: Any?           // timeObserver引用
    private var currentProgressCallback: ((CMTime) -> Void)?
    
    // 当前绑定的layer和状态
    private weak var activeLayer: AVPlayerLayer?
    private var isMainPlayerActive = true     // true: mainPlayer激活，false: warmupPlayer激活
    
    // 音频会话配置
    private var audioSessionConfigured = false
    
    // MARK: - 初始化
    override init() {
        super.init()
        setupPlayers()
        setupAudioSession()
    }
    
    // MARK: - 播放器设置
    private func setupPlayers() {
        // 配置主播放器
        mainPlayer.automaticallyWaitsToMinimizeStalling = true
        mainPlayer.preventsDisplaySleepDuringVideoPlayback = true
        mainPlayer.allowsExternalPlayback = false
        
        // 配置预热播放器
        warmupPlayer.automaticallyWaitsToMinimizeStalling = true
        warmupPlayer.preventsDisplaySleepDuringVideoPlayback = false
        warmupPlayer.allowsExternalPlayback = false
        warmupPlayer.isMuted = true  // 预热播放器静音
        
        print("VideoPlayerPool: 播放器初始化完成")
    }
    
    // MARK: - 音频会话配置
    private func setupAudioSession() {
        guard !audioSessionConfigured else { return }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, 
                                       mode: .moviePlayback, 
                                       options: [.allowBluetooth, .interruptSpokenAudioAndMixWithOthers])
            try audioSession.setActive(true)
            
            // 注册音频中断通知
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioInterruption(_:)),
                name: AVAudioSession.interruptionNotification,
                object: nil
            )
            
            audioSessionConfigured = true
            print("VideoPlayerPool: 音频会话配置完成")
        } catch {
            print("VideoPlayerPool: 音频会话配置失败 - \(error.localizedDescription)")
        }
    }
    
    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        switch type {
        case .began:
            // 中断开始 - 暂停播放
            pause()
            print("VideoPlayerPool: 音频中断开始，暂停播放")
        case .ended:
            // 中断结束 - 可能恢复播放
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // 这里可以选择自动恢复播放，但通常让用户主动恢复更好
                    print("VideoPlayerPool: 音频中断结束，可恢复播放")
                }
            }
        @unknown default:
            break
        }
    }
    
    // MARK: - 核心接口
    
    /// 当前激活的 AVPlayer（供外部绑定到 ASVideoNode.player）
    public var activePlayer: AVPlayer { getActivePlayer() }
    
    /// 设置当前播放项（不涉及 layer 绑定，便于与 ASVideoNode.player 配合）
    /// - Parameters:
    ///   - item: 要播放的 AVPlayerItem
    ///   - muted: 是否静音
    public func setCurrentItem(_ item: AVPlayerItem?, muted: Bool = false) {
        // 生成新的代际token
        let newToken = UUID()
        activeItemToken = newToken
        
        // 清理旧的观察者
        removePeriodicObserver()
        
        // 获取当前激活的播放器
        let activePlayer = getActivePlayer()
        
        // 取消之前的pending seeks
        activePlayer.currentItem?.cancelPendingSeeks()
        
        // 替换播放项
        activePlayer.replaceCurrentItem(with: item)
        activePlayer.isMuted = muted
        
        print("VideoPlayerPool: 设置当前播放项 - Token: \(newToken.uuidString.prefix(8))")
    }
    
    /// 将播放器绑定到指定的layer并播放item
    /// - Parameters:
    ///   - item: 要播放的AVPlayerItem
    ///   - layer: 目标AVPlayerLayer
    ///   - muted: 是否静音
    func attach(item: AVPlayerItem?, to layer: AVPlayerLayer, muted: Bool = false) {
        // 必须在主线程执行layer绑定
        DispatchQueue.main.async { [weak self] in
            self?._attachOnMainThread(item: item, to: layer, muted: muted)
        }
    }
    
    private func _attachOnMainThread(item: AVPlayerItem?, to layer: AVPlayerLayer, muted: Bool) {
        // 生成新的代际token
        let newToken = UUID()
        activeItemToken = newToken
        
        // 清理旧的观察者
        removePeriodicObserver()
        
        // 获取当前激活的播放器
        let activePlayer = getActivePlayer()
        
        // 取消之前的pending seeks
        activePlayer.currentItem?.cancelPendingSeeks()
        
        // 替换播放项
        activePlayer.replaceCurrentItem(with: item)
        activePlayer.isMuted = muted
        
        // 绑定到layer
        activeLayer = layer
        layer.player = activePlayer
        
        print("VideoPlayerPool: 播放器绑定完成 - Token: \(newToken.uuidString.prefix(8))")
    }
    
    /// 开始播放
    func play() {
        DispatchQueue.main.async { [weak self] in
            self?.getActivePlayer().play()
        }
    }
    
    /// 暂停播放
    func pause() {
        DispatchQueue.main.async { [weak self] in
            self?.getActivePlayer().pause()
        }
    }
    
    /// 跳转到指定时间
    /// - Parameters:
    ///   - time: 目标时间
    ///   - completion: 完成回调
    func seek(to time: CMTime, completion: @escaping (Bool) -> Void) {
        let currentToken = activeItemToken
        let activePlayer = getActivePlayer()
        
        // 取消pending seeks
        activePlayer.currentItem?.cancelPendingSeeks()
        
        // 使用容差seek提升性能
        let tolerance = CMTime(seconds: 0.25, preferredTimescale: 600)
        
        activePlayer.seek(to: time, toleranceBefore: tolerance, toleranceAfter: tolerance) { [weak self] finished in
            DispatchQueue.main.async {
                // 检查token是否仍然有效
                guard currentToken == self?.activeItemToken else {
                    completion(false)
                    return
                }
                completion(finished)
            }
        }
    }
    
    /// 添加周期性时间观察者（仅对当前激活的播放器）
    /// - Parameters:
    ///   - fps: 更新频率（帧率）
    ///   - callback: 进度回调
    func addPeriodicObserver(fps: Int = 15, callback: @escaping (CMTime) -> Void) {
        removePeriodicObserver()
        
        let interval = CMTime(value: 1, timescale: CMTimeScale(fps))
        let currentToken = activeItemToken
        
        timeObserver = getActivePlayer().addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            // 检查token有效性，防止过期回调
            guard currentToken == self?.activeItemToken else { return }
            callback(time)
        }
        
        currentProgressCallback = callback
        print("VideoPlayerPool: 添加进度观察者 - FPS: \(fps)")
    }
    
    /// 移除周期性时间观察者
    func removePeriodicObserver() {
        if let observer = timeObserver {
            getActivePlayer().removeTimeObserver(observer)
            timeObserver = nil
            currentProgressCallback = nil
            print("VideoPlayerPool: 移除进度观察者")
        }
    }
    
    /// 解绑当前layer
    func detach() {
        DispatchQueue.main.async { [weak self] in
            self?.activeLayer?.player = nil
            self?.activeLayer = nil
            self?.removePeriodicObserver()
            self?.activeItemToken = nil
            
            print("VideoPlayerPool: 播放器解绑完成")
        }
    }
    
    // MARK: - 预热功能
    
    /// 预热下一个视频资源
    /// - Parameters:
    ///   - asset: 要预热的AVURLAsset
    ///   - completion: 预热完成回调
    func prepareNext(asset: AVURLAsset, completion: @escaping (Result<AVPlayerItem, Error>) -> Void) {
        // 在后台线程进行asset加载
        DispatchQueue.global(qos: .utility).async {
            let keys = ["playable", "duration", "tracks"]
            
            asset.loadValuesAsynchronously(forKeys: keys) {
                DispatchQueue.main.async {
                    // 检查加载状态
                    for key in keys {
                        var error: NSError?
                        let status = asset.statusOfValue(forKey: key, error: &error)
                        
                        if status == .failed {
                            completion(.failure(error ?? NSError(domain: "VideoPlayerPool", code: -1, userInfo: [NSLocalizedDescriptionKey: "Asset加载失败: \(key)"])))
                            return
                        }
                    }
                    
                    // 创建PlayerItem并配置
                    let item = AVPlayerItem(asset: asset)
                    self.configurePlayerItem(item)
                    
                    // 使用预热播放器加载
                    self.warmupPlayer.replaceCurrentItem(with: item)
                    
                    completion(.success(item))
                    print("VideoPlayerPool: 预热完成 - \(asset.url)")
                }
            }
        }
    }
    
    /// 切换到预热的播放器（当滑动到下一个视频时）
    func switchToWarmupPlayer() -> Bool {
        guard warmupPlayer.currentItem != nil else { return false }
        
        // 交换主播放器和预热播放器的角色
        isMainPlayerActive.toggle()
        
        // 更新当前激活的layer
        if let layer = activeLayer {
            layer.player = getActivePlayer()
        }
        
        print("VideoPlayerPool: 切换到预热播放器")
        return true
    }
    
    // MARK: - 私有方法
    
    private func getActivePlayer() -> AVPlayer {
        return isMainPlayerActive ? mainPlayer : warmupPlayer
    }
    
    private func configurePlayerItem(_ item: AVPlayerItem) {
        // 配置播放项的缓冲策略
        item.preferredForwardBufferDuration = 4.0
        
        // 根据网络状况调整码率（可选）
        // item.preferredPeakBitRate = NetworkMonitor.shared.isHighBandwidth ? 5_000_000 : 2_000_000
    }
    
    // MARK: - 获取播放状态
    
    /// 获取当前播放时间
    var currentTime: CMTime {
        return getActivePlayer().currentTime()
    }
    
    /// 获取当前播放项的时长
    var duration: CMTime {
        return getActivePlayer().currentItem?.duration ?? .zero
    }
    
    /// 获取当前播放状态
    var isPlaying: Bool {
        return getActivePlayer().rate > 0
    }
    
    /// 获取当前播放进度（0-1）
    var progress: Double {
        let current = currentTime.seconds
        let total = duration.seconds
        guard total > 0 else { return 0 }
        return current / total
    }
    
    // MARK: - 清理
    deinit {
        removePeriodicObserver()
        NotificationCenter.default.removeObserver(self)
        print("VideoPlayerPool: 已销毁")
    }
}

// MARK: - 扩展：观察者中心功能
extension VideoPlayerPool {
    
    /// 统一的观察者管理器
    class ObserverCenter {
        private var observations: [NSKeyValueObservation] = []
        private var notificationObservers: [NSObjectProtocol] = []
        
        func addKVOObserver<T: NSObject>(_ object: T, keyPath: KeyPath<T, Any>, options: NSKeyValueObservingOptions = [.initial, .new], callback: @escaping (T, NSKeyValueObservedChange<Any>) -> Void) {
            let observation = object.observe(keyPath, options: options, changeHandler: callback)
            observations.append(observation)
        }
        
        func addNotificationObserver(name: Notification.Name, object: Any? = nil, callback: @escaping (Notification) -> Void) {
            let observer = NotificationCenter.default.addObserver(forName: name, object: object, queue: .main, using: callback)
            notificationObservers.append(observer)
        }
        
        func removeAll() {
            observations.removeAll()
            notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
            notificationObservers.removeAll()
        }
        
        deinit {
            removeAll()
        }
    }
}