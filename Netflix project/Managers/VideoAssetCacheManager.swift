import Foundation
import AVFoundation

final class VideoAssetCacheManager {
	static let shared = VideoAssetCacheManager()
	
	private let cache = NSCache<NSString, AVURLAsset>()
	private let queue = DispatchQueue(label: "video.asset.preload.queue")
	
	private init() {
		cache.countLimit = 50
	}
	
	func asset(for url: URL) -> AVURLAsset? {
		return cache.object(forKey: url.absoluteString as NSString)
	}
	
	func preload(urls: [URL], completion: (() -> Void)? = nil) {
		guard !urls.isEmpty else { completion?(); return }
		let group = DispatchGroup()
		for url in urls {
			if cache.object(forKey: url.absoluteString as NSString) != nil { continue }
			group.enter()
			queue.async {
				let asset = AVURLAsset(url: url)
				let keys = ["playable", "duration"]
				asset.loadValuesAsynchronously(forKeys: keys) { [weak self] in
					self?.cache.setObject(asset, forKey: url.absoluteString as NSString)
					group.leave()
				}
			}
		}
		group.notify(queue: .main) {
			completion?()
		}
	}
}
