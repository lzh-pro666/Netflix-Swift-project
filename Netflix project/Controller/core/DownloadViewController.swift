//
//  DownloadViewController.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/4/10.
//

import UIKit
import AVKit

class DownloadViewController: UIViewController  {

    private var titles: [TitleItem] = [TitleItem]()
    private var videos: [VideoItem] = [VideoItem]()
    // 定义一个 tableview
    private let downloadedTable: UITableView = {
        let table = UITableView()
        table.register(TitleTableViewCell.self, forCellReuseIdentifier: TitleTableViewCell.identifier)
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Downloads"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        downloadedTable.delegate = self
        downloadedTable.dataSource = self
        view.addSubview(downloadedTable)
        
        // 加载下载的影片和视频
        fetchLocalStorageForDownload()
        fetchLocalVideos()
        
        // 注册通知，当影片或视频下载完成时刷新界面
        NotificationCenter.default.addObserver(forName: NSNotification.Name("downloaded"), object: nil, queue: nil) { _ in
            self.fetchLocalStorageForDownload()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("videoDownloaded"), object: nil, queue: nil) { _ in
            self.fetchLocalVideos()
        }
    }
    
    private func fetchLocalStorageForDownload(){
        DataPersistenceManager.shared.fetchingTitlesFromDataBase { [weak self] result in
            switch result{
            case .success(let titles):
                self?.titles = titles
                self?.downloadedTable.reloadData()
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    // 获取所有下载的视频
    private func fetchLocalVideos() {
        DataPersistenceManager.shared.fetchingVideosFromDataBase { [weak self] result in
            switch result {
            case .success(let videos):
                self?.videos = videos
                self?.downloadedTable.reloadData()
            case .failure(let error):
                print("获取视频失败: \(error.localizedDescription)")
            }
        }
    }
    
    // 根据影片ID查找对应的视频
    private func findVideoForTitle(_ titleID: Int) -> VideoItem? {
        return videos.first { $0.id == titleID }
    }
    
    // 播放本地视频
    private func playLocalVideo(_ videoItem: VideoItem) {
        guard let localPath = videoItem.localPath, !localPath.isEmpty else {
            print("没有本地视频文件")
            return
        }
        
        let videoURL = URL(fileURLWithPath: localPath)
        
        // 创建AVPlayer和AVPlayerViewController
        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        // 展示播放器
        present(playerViewController, animated: true) {
            player.play()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        downloadedTable.frame = view.bounds
    }
}


extension DownloadViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleTableViewCell.identifier, for: indexPath) as? TitleTableViewCell else {
            return UITableViewCell()
        }
        
        let title = titles[indexPath.row]
        
        // 使用更新的TitleViewModel配置cell
        cell.configure(with: TitleViewModel(
            titleName: title.original_title ?? title.original_name ?? "未知",
            posterURL: title.poster_path ?? "",
            id: Int(title.id)
        ))
        
        // 设置播放按钮点击回调
        cell.playButtonTapHandler = { [weak self] in
            // 查找对应的视频
            if let titleID = Int(exactly: title.id), let videoItem = self?.findVideoForTitle(titleID) {
                // 播放本地视频
                self?.playLocalVideo(videoItem)
            } else {
                // 如果没有本地视频，提示用户
                let alert = UIAlertController(
                    title: "无法播放",
                    message: "未找到对应的视频文件，请先下载视频",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "确定", style: .default))
                self?.present(alert, animated: true)
            }
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            DataPersistenceManager.shared.deleteTitlesWith(model: titles[indexPath.row]) { [weak self] result in
                switch result{
                case .success():
                    print("delete from the database")
                case .failure(let error):
                    print(error.localizedDescription)
                }
                self?.titles.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        default:
            break;
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let title = titles[indexPath.row]
        
        guard let titleName = title.original_title ?? title.original_name else {
            return
        }
        
        APICaller.shared.getMovie(with: titleName) {[weak self] result in
            switch result{
            case .success(let videoElement):
                DispatchQueue.main.async {
                    let vc = TitlePreviewViewController()
                    vc.configure(with: TitlePreviewViewModel(title: titleName, youtubeView: videoElement, titleOverview: title.overview ?? ""))
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
}
