import Foundation
import AVFoundation
import CachingPlayerItem

// MARK: - 视频 Feed 数据模型
struct VideoFeedModel: Codable {
    let id: String
    let title: String
    let description: String
    let videoURL: String
    let thumbnailURL: String?
    let duration: TimeInterval
    let author: String
    let likes: Int
    let views: Int
    let createdAt: Date
    
    // 本地测试视频路径
    var localVideoPath: String? {
        // 根据 ID 映射到本地测试视频（替换为 @video test/ 的所有视频）
        let names = [
            "a29ab7a8c7925191140e68e1336e4748",
            "10a927676b9b12e411c3f078c368c11e",
            "ccbcd0fdd426abc0a4424923366866d8",
            "40d37e267cda750997796e74f8148843",
            "d3c24f87cfdff6169535587eb4d267b7",
            "d858fc83de7fbdb8bfc1daab88dacad0",
            "7a6224474d3d7d8ff2427d647ce93dae",
            "b3bc45618a61172ac225d67309ebc193",
            "6e170e3a5049f23262a20cdc21ec5c88",
            "4357d557bf638a5eb14a6a4c301acf37",
            "308407c240ca8bf58b030f214feeae78",
        ]
        if let idx = Int(id), idx > 0, idx <= names.count {
            return Bundle.main.path(forResource: names[idx-1], ofType: "mp4")
        }
        return nil
    }
    
    // 创建本地测试数据
    static func createTestData() -> [VideoFeedModel] {
        let count = 11
        return (1...count).map { i in
            VideoFeedModel(
                id: "\(i)",
                title: "精彩瞬间 #\(i)",
                description: "本地测试视频 #\(i)",
                videoURL: "",
                thumbnailURL: nil,
                duration: 15.0,
                author: "创作者#\(i)",
                likes: 1000 + i,
                views: 5000 + i * 10,
                createdAt: Date()
            )
        }
    }
}

// MARK: - 视频播放状态
enum VideoPlaybackState {
    case idle
    case loading
    case playing
    case paused
    case finished
    case error(String)
}

// MARK: - 视频缓存管理
class VideoCacheManager {
    static let shared = VideoCacheManager()
    
    private let cache = NSCache<NSString, CachingPlayerItem>()
    private let maxCacheSize = 10 // 最大缓存数量
    
    private init() {
        cache.countLimit = maxCacheSize
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }
    
    func getCachedItem(for url: URL) -> CachingPlayerItem? {
        return cache.object(forKey: url.absoluteString as NSString)
    }
    
    func cacheItem(_ item: CachingPlayerItem, for url: URL) {
        cache.setObject(item, forKey: url.absoluteString as NSString)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
