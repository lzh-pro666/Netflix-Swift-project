//
//  UpcomingViewController.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/4/10.
//

import UIKit

class UpcomingViewController: UIViewController {

    private var titles:[Title] = [Title]()
    
    // 添加属性记录上次点击时间
    private var lastClickTime: Date?
    // 定义一个 tableview
    private let upcomingTable: UITableView = {
        let table = UITableView()
        table.register(TitleTableViewCell.self, forCellReuseIdentifier: TitleTableViewCell.identifier)
        return table
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "UPcoming"
        
        // 设置导航栏
        configureNavigationBar()
        
        view.addSubview(upcomingTable)
        upcomingTable.delegate = self
        upcomingTable.dataSource = self
        fetchUpcoming()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        upcomingTable.frame = view.bounds
    }
    
    private func fetchUpcoming() {
        APICaller.shared.getUpcomingMovie { [weak self] result in
            switch result {
            case .success(let titles):
                self?.titles = titles
                DispatchQueue.main.async {
                    self?.upcomingTable.reloadData()
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    private func configureNavigationBar() {
        // 设置导航栏标题为大标题
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        // 设置返回按钮为白色加粗
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 17)
        ]
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.backButtonAppearance = backButtonAppearance
        navBarAppearance.setBackIndicatorImage(
            UIImage(systemName: "chevron.backward")?.withTintColor(.white, renderingMode: .alwaysOriginal),
            transitionMaskImage: UIImage(systemName: "chevron.backward")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        )
        
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
    }

}
// 扩展类实现代理和数据源方法
extension UpcomingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleTableViewCell.identifier, for: indexPath) as? TitleTableViewCell else {
            return UITableViewCell()
        }
        let title = titles[indexPath.row]
        cell.configure(with: TitleViewModel(titleName: title.original_title ?? title.original_title ?? "unKnow", posterURL: title.poster_path ?? ""))
        
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
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
