//
//  SearcherViewController.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/4/10.
//

import UIKit

class SearcherViewController: UIViewController  {

    private var titles:[Title] = [Title]()
    
    // 添加属性记录上次点击时间
    private var lastClickTime: Date?
    
    private let discoverTable: UITableView = {
       let table = UITableView()
        table.register(TitleTableViewCell.self, forCellReuseIdentifier: TitleTableViewCell.identifier)
        return table
    }()
    
    // 定义搜索栏
    private let searchController: UISearchController = {
       let controller = UISearchController(searchResultsController: SearcherResultsViewController())
        controller.searchBar.placeholder = "Seachar for a Movie or Tv show"
        controller.searchBar.searchBarStyle = .prominent
        return controller
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Search"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        view.addSubview(discoverTable)
        discoverTable.delegate = self
        discoverTable.dataSource = self
        
        navigationItem.searchController = searchController
        navigationController?.navigationBar.tintColor = .white
        
        // 将 searchController 的 searchResultsUpdater 属性设置为当前对象（self）。表示当前对象（通常是一个 UIViewController）将负责处理搜索结果的更新逻辑。
        searchController.searchResultsUpdater = self
        fetchUpcoming()
    }
    
    private func fetchUpcoming() {
        APICaller.shared.getDiscoverMovies{ [weak self] result in
            switch result {
            case .success(let titles):
                self?.titles = titles
                DispatchQueue.main.async {
                    self?.discoverTable.reloadData()
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        discoverTable.frame = view.bounds
    }

}

extension SearcherViewController: UITableViewDelegate
,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleTableViewCell.identifier, for: indexPath) as? TitleTableViewCell else {
            return UITableViewCell()
        }
        let title = titles[indexPath.row]
        let model = TitleViewModel(titleName: title.original_name ?? title.original_title ?? "unKnow", posterURL: title.poster_path ?? "")
        cell.configure(with: model)
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
        
        guard let titleName = title.original_name ?? title.original_title else {
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

extension SearcherViewController: UISearchResultsUpdating, SearcherResultsViewControllerDeleage{
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        
        guard let query = searchBar.text,
              // 移除 query 字符串首尾的空白字符,并且检查移除空白字符后的字符串是否为空
              !query.trimmingCharacters(in: .whitespaces).isEmpty,
              // 确保移除空白字符后的字符串长度至少为 3 个字符。为了避免频繁发起无效搜索（例如只输入“s”）。
              query.trimmingCharacters(in: .whitespaces).count >= 3,
              let resultsController = searchController.searchResultsController as? SearcherResultsViewController else {
                        return
        }
        resultsController.deleage = self
        
        APICaller.shared.search(with: query) { result in
            DispatchQueue.main.async {
                switch result{
                case .success(let titles):
                    resultsController.titles = titles
                    resultsController.searcherResultsCollectionView.reloadData()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    func searcherResultsViewControllerDidTapItem(_ viewModel: TitlePreviewViewModel) {
        DispatchQueue.main.async { [weak self] in
            let vc = TitlePreviewViewController()
            vc.configure(with: viewModel)
            self?.navigationController?.pushViewController(vc, animated: true)
        }

    }
    
}
