import UIKit
import AsyncDisplayKit
import IGListKit
import AVFoundation
import Network

// MARK: - Shorts 视图控制器
class ShortsViewController: UIViewController {
    
    // MARK: - 属性
    private var collectionNode: ASCollectionNode!
    private var videoModels: [VideoFeedModel] = []
    private var currentPlayingIndex: Int = 0
    private var viewModel = VideoFeedViewModel()
    private var currentBottomInset: CGFloat = 0
    
    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionNode()
        setupMonitoring()
        loadData()
        initialPreload()
        
        // 初始化底部安全区 inset
        currentBottomInset = view.safeAreaInsets.bottom
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 更新底部安全区 inset
        let newBottomInset = view.safeAreaInsets.bottom
        if newBottomInset != currentBottomInset {
            currentBottomInset = newBottomInset
            // 重新加载可见的单元格以更新布局
            collectionNode.reloadData()
        }
    }
    
    // MARK: - 计算底部内容区域
    private func calculateBottomContentArea() -> CGFloat {
        // 计算底部内容区域：TabBar 高度 + 底部安全区域
        let tabBarHeight: CGFloat = 49 // 标准 TabBar 高度
        let bottomSafeArea = view.safeAreaInsets.bottom
        return tabBarHeight + bottomSafeArea
    }
    
    // MARK: - 计算 CollectionView 高度
    private func calculateCollectionViewHeight() -> CGFloat {
        // 恢复为原先的高度：屏幕高度减去 TabBar 高度
        let screenHeight = UIScreen.main.bounds.height
        let tabBarHeight: CGFloat = 49
        return screenHeight - tabBarHeight
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 设置状态栏样式
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: - UI 设置
    private func setupUI() {
        view.backgroundColor = .black
        
        // 修复顶部黑色区域：设置导航栏样式
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.backgroundColor = .black
        navigationController?.navigationBar.tintColor = .white
        
        // 隐藏导航栏，让视频占满顶部
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 设置状态栏样式
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: - 状态栏样式
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return true  // 隐藏状态栏
    }
    
    override var childForStatusBarHidden: UIViewController? {
        return nil
    }
    
    // MARK: - 数据加载
    private func loadData() {
        // 加载测试数据
        videoModels = VideoFeedModel.createTestData()
        viewModel.loadInitial(items: videoModels)
    }
    
    // MARK: - Collection Node 设置
    private func setupCollectionNode() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        // 设置明确的 item 尺寸，避免尺寸计算问题
        let screenSize = UIScreen.main.bounds.size
        // 关键修复：每个 cell 的高度应该是屏幕的全高，避免底部留空黑条
        let collectionViewHeight = calculateCollectionViewHeight()
        layout.itemSize = CGSize(width: screenSize.width, height: collectionViewHeight)
        
        collectionNode = ASCollectionNode(frame: view.bounds, collectionViewLayout: layout)
        collectionNode.backgroundColor = .black  // 与整体背景一致
        collectionNode.delegate = self
        collectionNode.dataSource = self
        
        // 设置分页 - 每个 cell 占满 CollectionView 的高度
        collectionNode.isPagingEnabled = true
        
        // 设置滚动行为
        collectionNode.view.showsVerticalScrollIndicator = false
        collectionNode.view.showsHorizontalScrollIndicator = false
        collectionNode.view.contentInsetAdjustmentBehavior = .never
        
        view.addSubnode(collectionNode)
        
        // 使用 Auto Layout 约束，确保 CollectionView 完全贴合屏幕边缘
        collectionNode.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionNode.view.topAnchor.constraint(equalTo: view.topAnchor),
            collectionNode.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionNode.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // 恢复为固定高度约束，而不是贴到底部
            collectionNode.view.heightAnchor.constraint(equalToConstant: collectionViewHeight)
        ])
    }
    
    // MARK: - 监控设置
    private func setupMonitoring() {
        // 启动性能监控
        PerformanceMonitor.shared.startMonitoring()
        
        // 设置性能监控回调
        PerformanceMonitor.shared.onMetricsUpdated = { [weak self] metrics in
            // 这里可以更新 UI 显示性能指标
            print("性能指标更新: FPS=\(String(format: "%.1f", metrics.fps))")
        }
        
        PerformanceMonitor.shared.onPerformanceWarning = { warning in
            print("性能警告: \(warning)")
        }
        
        // 设置网络监控回调
        NetworkMonitor.shared.onNetworkStatusChanged = { [weak self] isConnected, type in
            if isConnected {
                print("网络已连接: \(type?.displayName ?? "unknown")")
            } else {
                print("网络已断开")
            }
        }
        
        NetworkMonitor.shared.onNetworkTypeChanged = { type in
            print("网络类型变化: \(type.displayName)")
        }
    }
    
    // MARK: - 滚动处理
    private func handleScrollToIndex(_ index: Int) {
        guard index >= 0 && index < videoModels.count else { return }
        
        let indexPath = IndexPath(item: index, section: 0)
        collectionNode.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
        
        // 更新当前播放索引
        currentPlayingIndex = index
        
        // 通知当前可见的单元格开始播放
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let cell = self.collectionNode.nodeForItem(at: indexPath) as? VideoFeedCell {
                // 这里可以添加播放逻辑
            }
        }
    }
    
    private func initialPreload() {
        viewModel.preloadInitial()
    }
    
    private func preloadNextBatch(from startIndex: Int) {
        let urls = viewModel.urlsForBatch(start: startIndex)
        VideoAssetCacheManager.shared.preload(urls: urls)
    }
}

// MARK: - ASCollectionDataSource
extension ShortsViewController: ASCollectionDataSource {
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return videoModels.count
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let videoModel = videoModels[indexPath.item]
        // 传递底部内容区域 inset（TabBar 高度 + 安全区），以便单元格内部避让
        let bottomInset: CGFloat = calculateBottomContentArea()
        return {
            VideoFeedCell(videoModel: videoModel, bottomContentInset: bottomInset)
        }
    }
}

// MARK: - ASCollectionDelegate
extension ShortsViewController: ASCollectionDelegate {
    func collectionNode(_ collectionNode: ASCollectionNode, didEndDisplaying node: ASCellNode, forItemAt indexPath: IndexPath) {
        // 当单元格不可见时，可以暂停视频播放
        if let videoCell = node as? VideoFeedCell {
            // 暂停播放逻辑已在 VideoFeedCell 中处理
        }
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, willBeginBatchFetchWith context: ASBatchContext) {
        // 预加载更多数据
        context.completeBatchFetching(true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let centerPoint = CGPoint(x: scrollView.contentOffset.x + scrollView.bounds.width / 2,
                                  y: scrollView.contentOffset.y + scrollView.bounds.height / 2)
        if let indexPath = collectionNode.indexPathForItem(at: centerPoint) {
            currentPlayingIndex = indexPath.item
            // 当剩余不足等于2个时，预加载下一批
            if videoModels.count - currentPlayingIndex <= 2 {
                preloadNextBatch(from: currentPlayingIndex + 1)
            }
            print("当前播放索引: \(currentPlayingIndex)")
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            // 如果拖拽后没有减速，说明滚动已经停止
            let centerPoint = CGPoint(x: scrollView.contentOffset.x + scrollView.bounds.width / 2,
                                     y: scrollView.contentOffset.y + scrollView.bounds.height / 2)
            
            if let indexPath = collectionNode.indexPathForItem(at: centerPoint) {
                currentPlayingIndex = indexPath.item
                print("拖拽后当前播放索引: \(currentPlayingIndex)")
            }
        }
    }
}

// MARK: - 视频播放管理
extension ShortsViewController {
    
    /// 播放指定索引的视频
    func playVideo(at index: Int) {
        guard index >= 0 && index < videoModels.count else { return }
        
        let indexPath = IndexPath(item: index, section: 0)
        if let cell = collectionNode.nodeForItem(at: indexPath) as? VideoFeedCell {
            // 这里可以添加播放逻辑
            print("开始播放视频: \(videoModels[index].title)")
        }
    }
    
    /// 暂停当前播放的视频
    func pauseCurrentVideo() {
        let indexPath = IndexPath(item: currentPlayingIndex, section: 0)
        if let cell = collectionNode.nodeForItem(at: indexPath) as? VideoFeedCell {
            // 这里可以添加暂停逻辑
            print("暂停播放视频: \(videoModels[currentPlayingIndex].title)")
        }
    }
    
            /// 跳转到指定视频
        func jumpToVideo(at index: Int) {
            handleScrollToIndex(index)
        }
        
        /// 预加载下一个视频
        func preloadNextVideo() {
            let nextIndex = currentPlayingIndex + 1
            guard nextIndex < videoModels.count else { return }
            
            let videoModel = videoModels[nextIndex]
            if let localPath = videoModel.localVideoPath {
                let url = URL(fileURLWithPath: localPath)
                VideoPlaybackManager.shared.preloadVideo(with: url)
                print("预加载下一个视频: \(videoModel.title)")
            }
        }
    }
