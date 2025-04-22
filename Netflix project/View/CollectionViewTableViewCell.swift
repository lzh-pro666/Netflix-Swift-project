//
//  CollectionViewTableViewCell.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/4/10.
//

import UIKit
//  定义代理单元格代理
protocol CollectionViewTableViewCellDelegate: AnyObject{
    // 这个方法允许单元格将事件或数据传递给实现协议的对象（通常是视图控制器）。
    //例如，当用户点击单元格中的某个元素（可能是一个嵌套的 UICollectionView 单元格），单元格可以通过此方法通知委托方，传递相关单元格和数据模型。
    func collectionViewTableViewCellDidTapCell(_ cell: CollectionViewTableViewCell, viewmodel: TitlePreviewViewModel)
}

class CollectionViewTableViewCell: UITableViewCell {
    
    // 添加属性记录上次点击时间
    private var lastClickTime: Date?
    // 定义复用标识符，并且表示它属于类本身，而不是类的实例
    static let identifier = "CollectionViewTableViewCell"
    
    // 在委托模式中，CollectionViewTableViewCell 和其 delegate（通常是视图控制器）之间可能形成循环引用
    weak var delegate: CollectionViewTableViewCellDelegate?
    
    private var titles: [Title] = [Title]()
    //定义横向的 collectionview
    private let collectionView: UICollectionView = {
       
        // 先定义布局
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 140, height: 200)
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TitleCollectionViewCell.self, forCellWithReuseIdentifier: TitleCollectionViewCell.identifier)
        return collectionView
    }()
    
    
    // 重写父类的初始化方法（init(style:reuseIdentifier:) 是 UITableViewCell 的指定初始化方法）
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        // 添加 collectionview
        contentView.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    // required 表示这个方法是必须实现的，因为父类 UITableViewCell 实现了 NSCoding 协议，子类必须提供实现。
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = contentView.bounds
    }
    
    public func configure(with titles: [Title]){
        self.titles = titles
        // 在主线程上异步调用collectionView.reloadData()刷新视图
        DispatchQueue.main.async {[weak self] in
            self?.collectionView.reloadData()
        }
    }
    private func downloadTitleAt(indexPath: IndexPath){
        // 获取当前影片
        let title = titles[indexPath.row]
        // 先保存影片信息到数据库
        DataPersistenceManager.shared.downloadTitleWith(model: title) { [weak self] result in
            switch result{
            case .success():
                // 广播一个下载通知
                NotificationCenter.default.post(name: NSNotification.Name("downloaded"), object: nil)
                // 获取影片名称用于搜索视频
                guard let titleName = title.original_title ?? title.original_name else {
                    return
                }
                
                // 查询视频下载链接
                APICaller.shared.getDownloadMovie(with: titleName) { [weak self] result in
                    switch result {
                    case .success(let pexelsVideo):
                        // 确保有视频文件
                        guard !pexelsVideo.videoFiles.isEmpty else {
                            print("没有可用的视频文件")
                            return
                        }
                        
                        // 获取视频链接
                        let videoUrl = pexelsVideo.url
                        let videoLink = pexelsVideo.videoFiles[0].link
                        
                        // 下载视频到本地
                        self?.downloadVideoFile(id: title.id, url: videoUrl, link: videoLink)
                        
                    case .failure(let error):
                        print("获取视频下载链接失败: \(error.localizedDescription)")
                    }
                }
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    // 下载视频文件到本地
    private func downloadVideoFile(id: Int, url: String, link: String) {
        guard let videoURL = URL(string: link) else {
            print("无效的视频URL")
            return
        }
        
        let downloadTask = URLSession.shared.downloadTask(with: videoURL) { (location, response, error) in
            guard let location = location, error == nil else {
                print("下载视频失败: \(error?.localizedDescription ?? "未知错误")")
                return
            }
            
            // 创建本地存储路径
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsDirectory.appendingPathComponent("\(id)_video.mp4")
            
            // 移动下载的临时文件到永久存储位置
            do {
                // 如果已存在同名文件，先删除
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.moveItem(at: location, to: destinationURL)
                print("视频已保存到: \(destinationURL.path)")
                
                // 保存视频信息到数据库
                DispatchQueue.main.async {
                    DataPersistenceManager.shared.downloadVideoWith(
                        id: id,
                        url: url,
                        link: link,
                        localPath: destinationURL.path
                    ) { result in
                        switch result {
                        case .success():
                            print("视频信息已保存到数据库")
                            // 发送视频下载完成通知
                            NotificationCenter.default.post(name: NSNotification.Name("videoDownloaded"), object: nil)
                        case .failure(let error):
                            print("保存视频信息失败: \(error.localizedDescription)")
                        }
                    }
                }
                
            } catch {
                print("保存视频文件失败: \(error.localizedDescription)")
            }
        }
        
        downloadTask.resume()
    }
}

// 扩展类实现代理和数据源方法
extension CollectionViewTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return titles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TitleCollectionViewCell.identifier, for: indexPath) as? TitleCollectionViewCell else {
            return UICollectionViewCell()
        }
        guard let model = titles[indexPath.row].poster_path else {
            return UICollectionViewCell()
        }
        
        cell.configure(with: model)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 获取当前时间
        let currentTime = Date()
                
        // 检查与上次点击的时间间隔
        if let lastTime = lastClickTime, currentTime.timeIntervalSince(lastTime) < 2 {
        // 如果间隔小于2秒，忽略此次点击
            return
        }
                
        // 更新上次点击时间
        lastClickTime = currentTime
        let title = titles[indexPath.row]
        guard let titleName = title.original_title ?? title.original_name else {
            return
        }
//        APICaller.shared.getDownloadMovie(with: titleName) { [weak self]result in
//            switch result{
//            case .success(let PexelsVideo):
//                print(PexelsVideo.id)
//            case .failure(let error):
//                print(error.localizedDescription)
//            }
//        }
        APICaller.shared.getMovie(with: titleName + " trailer") { [weak self]result in
            switch result{
            case .success(let videoElement):
                let title = self?.titles[indexPath.row]
                guard let titleOverview = title?.overview else{
                    return
                }
                let viewModel = TitlePreviewViewModel(title: titleName, youtubeView: videoElement, titleOverview: titleOverview)
                guard let strongSelf = self else{
                    return
                }
                self?.delegate?.collectionViewTableViewCellDidTapCell(strongSelf, viewmodel: viewModel)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    // 设置长按 cell
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil){ [weak self] _ in
                // 下载影片信息的选项
                let downloadTitleAction = UIAction(
                    title: "收藏影片", 
                    image: UIImage(systemName: "heart"),
                    identifier: nil,
                    discoverabilityTitle: nil, 
                    state: .off
                ){ _ in
                    self?.downloadTitleAt(indexPath: indexPaths[0])
                }
                
                // 下载并观看视频的选项
                let downloadVideoAction = UIAction(
                    title: "下载视频", 
                    image: UIImage(systemName: "arrow.down.circle"),
                    identifier: nil,
                    discoverabilityTitle: nil, 
                    state: .off
                ){ _ in
                    self?.downloadTitleAt(indexPath: indexPaths[0])
                }
                
                return UIMenu(
                    title: "", 
                    image: nil, 
                    identifier: nil,
                    options: .displayInline, 
                    children: [downloadTitleAction, downloadVideoAction]
                )
            }
        return config
    }
}


