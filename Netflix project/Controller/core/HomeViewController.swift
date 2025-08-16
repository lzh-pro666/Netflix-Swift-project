//
//  HomeViewController.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/3/10.
//

import UIKit

enum Section: Int {
    case TrendingMovie = 0
    case TrendingTv = 1
    case Popular = 2
    case Upcoming = 3
    case TopRated = 4
}


class HomeViewController: UIViewController {
    
    // 定义随机的大图视图
    private var randomTrendingMovie: Title?
    private var headerView: HeroHeaderUIView?
    // 定义分组的头名字
    let sactionTitle: [String] = ["Trending Movies","Trending Tv", "Popylar",  "Upcoming Movies", "Top rated" ]
    // 定义一个私有的 UITableView 属性 homeFeedTable，并用属性闭包匿名初始化
    private let homeFeedTable: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        // 注册 cell
        table.register(CollectionViewTableViewCell.self, forCellReuseIdentifier: CollectionViewTableViewCell.identifier)
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(homeFeedTable)
        // Do any additional setup after loading the view.
        //让当前 controller 作为代理和数据源方法
        homeFeedTable.delegate = self
        homeFeedTable.dataSource = self
        configureNavbar()
        
        
        headerView = HeroHeaderUIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 450))
        homeFeedTable.tableHeaderView = headerView
        configureHeroHeaderView()

    }
    //配置大图视图
    private func configureHeroHeaderView(){
        APICaller.shared.getTrendingMovie { [weak self] result in
            switch result{
            case .success(let titles):
                let selectedTitle = titles.randomElement()
                self?.randomTrendingMovie = selectedTitle
                self?.headerView?.configure(with: TitleViewModel(titleName: selectedTitle?.original_title ?? "", posterURL: selectedTitle?.poster_path ?? ""))
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    // 设置上边栏
    private func configureNavbar(){
        var image = UIImage(named: "netflixLogo")
        image = image?.withRenderingMode(.alwaysOriginal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: image, style: .done, target: self, action: nil)
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "person.circle"), style: .done, target: self, action: #selector(personButtonTapped)),
            UIBarButtonItem(image: UIImage(systemName: "play.rectangle"), style: .done, target: self, action: nil)
        ]
        navigationController?.navigationBar.tintColor = .label
        
    }
    
    @objc private func personButtonTapped() {
        let vc = UserProfileViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        homeFeedTable.frame = view.bounds
    }
    
    // 在离开页面前恢复导航栏状态
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 恢复导航栏transform，避免影响下一个页面
        navigationController?.navigationBar.transform = .identity
    }
    
}

// 通过扩展来实现代理和数据源方法
extension HomeViewController: UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sactionTitle.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CollectionViewTableViewCell.identifier, for: indexPath) as? CollectionViewTableViewCell else{
            return UITableViewCell()
        }
        cell.delegate = self
        // 根据滑动动态更新每一行的 collectionview
        switch indexPath.section{
        case Section.TrendingMovie.rawValue:
            APICaller.shared.getTrendingMovie{result in
                switch result {
                case .success(let titles):
                    cell.configure(with: titles)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        case Section.TrendingTv.rawValue:
            APICaller.shared.getTrendingTV { result in
                switch result{
                case .success(let titles):
                    cell.configure(with: titles)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        case Section.Popular.rawValue:
            APICaller.shared.getPopular { result in
                switch result{
                case .success(let titles):
                    cell.configure(with: titles)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        case Section.Upcoming.rawValue:
            APICaller.shared.getUpcomingMovie { result in
                switch result{
                case .success(let titles):
                    cell.configure(with: titles)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        case Section.TopRated.rawValue:
            APICaller.shared.getTopRate { result in
                switch result{
                case .success(let titles):
                    cell.configure(with: titles)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        default :
            return UITableViewCell()
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    // 设置在即将显示分区头部视图时调用方法来修改头部视图的样式、字体形式
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else {
            return
        }
        header.textLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        header.textLabel?.frame = CGRect(x: header.bounds.origin.x + 20, y: header.bounds.origin.y, width: 100, height: header.bounds.height)
        header.textLabel?.textColor = .label
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sactionTitle[section]
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let defaultOffset = view.safeAreaInsets.top
        let offset = scrollView.contentOffset.y + defaultOffset
        UIView.animate(withDuration: 0.05) {
                self.navigationController?.navigationBar.transform = .init(translationX: 0, y: min(0, -offset))
            }
    }
    
}

extension HomeViewController: CollectionViewTableViewCellDelegate{
    func collectionViewTableViewCellDidTapCell(_ cell: CollectionViewTableViewCell, viewmodel: TitlePreviewViewModel) {
        DispatchQueue.main.async { [weak self] in
            // 在推出新页面前恢复导航栏状态
            self?.navigationController?.navigationBar.transform = .identity
            
            let vc = TitlePreviewViewController()
            vc.configure(with: viewmodel)
            // 确保导航栏可见
            vc.navigationItem.largeTitleDisplayMode = .never
            self?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
