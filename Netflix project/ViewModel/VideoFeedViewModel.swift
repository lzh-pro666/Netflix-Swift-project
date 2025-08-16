import Foundation
import AVFoundation

final class VideoFeedViewModel {
	private(set) var items: [VideoFeedModel] = []
	private let preloadBatchSize: Int = 5
	
	func loadInitial(items: [VideoFeedModel]) {
		self.items = items
	}
	
	func urlsForBatch(start: Int) -> [URL] {
		guard start < items.count else { return [] }
		let end = min(start + preloadBatchSize, items.count)
		return (start..<end).compactMap { idx in
			if let path = items[idx].localVideoPath { return URL(fileURLWithPath: path) }
			return nil
		}
	}
	
	func preloadInitial() {
		VideoAssetCacheManager.shared.preload(urls: urlsForBatch(start: 0))
	}
	
	func preloadIfNeeded(currentIndex: Int) {
		let remain = items.count - currentIndex
		if remain <= 2 {
			VideoAssetCacheManager.shared.preload(urls: urlsForBatch(start: currentIndex + 1))
		}
	}
}
