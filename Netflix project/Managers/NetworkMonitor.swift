import Foundation
import Network

// MARK: - NWInterface.InterfaceType 扩展
extension NWInterface.InterfaceType {
    var displayName: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "蜂窝网络"
        case .wiredEthernet:
            return "有线网络"
        case .loopback:
            return "本地网络"
        @unknown default:
            return "未知网络"
        }
    }
}

// MARK: - 网络状态监控器
class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    // MARK: - 属性
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // MARK: - 网络状态
    private(set) var isConnected = false
    private(set) var connectionType: NWInterface.InterfaceType?
    private(set) var isExpensive = false
    
    // MARK: - 回调
    var onNetworkStatusChanged: ((Bool, NWInterface.InterfaceType?) -> Void)?
    var onNetworkTypeChanged: ((NWInterface.InterfaceType) -> Void)?
    
    private init() {
        setupMonitoring()
    }
    
    // MARK: - 监控设置
    private func setupMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handlePathUpdate(path)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    // MARK: - 路径更新处理
    private func handlePathUpdate(_ path: NWPath) {
        let wasConnected = isConnected
        let wasExpensive = isExpensive
        let wasConnectionType = connectionType
        
        // 更新状态
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        connectionType = path.availableInterfaces.first?.type
        
        // 检查连接状态变化
        if wasConnected != isConnected {
            onNetworkStatusChanged?(isConnected, connectionType)
            
            // 通知视频播放管理器
            VideoPlaybackManager.shared.handleNetworkStatusChange(isReachable: isConnected)
            
            print("网络状态变化: \(isConnected ? "已连接" : "已断开")")
        }
        
        // 检查连接类型变化
        if wasConnectionType != connectionType, let newType = connectionType {
            onNetworkTypeChanged?(newType)
            
            // 根据网络类型调整视频质量
            adjustVideoQuality(for: newType)
            
            print("网络类型变化: \(newType.displayName)")
        }
        
        // 检查网络费用变化
        if wasExpensive != isExpensive {
            print("网络费用状态变化: \(isExpensive ? "昂贵网络" : "普通网络")")
            
            // 在昂贵网络上调整预加载策略
            if isExpensive {
                VideoPlaybackManager.shared.clearPreloadQueue()
                print("检测到昂贵网络，暂停视频预加载")
            }
        }
    }
    
    // MARK: - 网络类型处理
    private func adjustVideoQuality(for interfaceType: NWInterface.InterfaceType) {
        switch interfaceType {
        case .wifi:
            // WiFi 网络，可以使用高质量视频
            print("WiFi 网络，启用高质量视频")
            enableHighQualityVideo()
            
        case .cellular:
            // 蜂窝网络，根据网络质量调整
            print("蜂窝网络，根据质量调整视频")
            adjustCellularVideoQuality()
            
        case .wiredEthernet:
            // 有线网络，使用最高质量
            print("有线网络，启用最高质量视频")
            enableHighestQualityVideo()
            
        case .loopback:
            // 本地回环，使用高质量
            print("本地网络，启用高质量视频")
            enableHighQualityVideo()
            
        @unknown default:
            // 未知网络类型，使用默认设置
            print("未知网络类型，使用默认设置")
            enableDefaultQualityVideo()
        }
    }
    
    // MARK: - 视频质量调整
    private func enableHighQualityVideo() {
        // 启用高质量视频设置
        // 这里可以设置视频分辨率、比特率等参数
    }
    
    private func adjustCellularVideoQuality() {
        // 根据蜂窝网络质量调整视频设置
        // 可以检测网络速度并相应调整
    }
    
    private func enableHighestQualityVideo() {
        // 启用最高质量视频设置
    }
    
    private func enableDefaultQualityVideo() {
        // 启用默认质量视频设置
    }
    
    // MARK: - 公共方法
    func startMonitoring() {
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    func getCurrentNetworkInfo() -> (isConnected: Bool, type: NWInterface.InterfaceType?, isExpensive: Bool) {
        return (isConnected, connectionType, isExpensive)
    }
    
    // MARK: - 网络质量检测
    func checkNetworkSpeed(completion: @escaping (Double) -> Void) {
        // 简单的网络速度检测
        let startTime = Date()
        
        // 这里可以实现实际的网络速度检测逻辑
        // 例如下载一个小文件并计算速度
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            // 模拟网络速度（实际项目中应该实现真实的检测）
            let simulatedSpeed = Double.random(in: 1.0...100.0) // Mbps
            
            DispatchQueue.main.async {
                completion(simulatedSpeed)
            }
        }
    }
    
    // MARK: - 清理
    deinit {
        stopMonitoring()
    }
}
