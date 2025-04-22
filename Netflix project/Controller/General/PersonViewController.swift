//
//  PersonViewController.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/4/15.
//

import UIKit

class UserProfileViewController: UIViewController {
    
    // 定义tableView
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    // 两组数据
    private let sections = ["账户信息", "底部导航栏设置"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "个人设置"
        
        // 设置tableView
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        // 设置初始默认值
        if UserDefaults.standard.object(forKey: "upcomingTabVisible") == nil {
            // 如果没有设置过，默认为true（显示）
            UserDefaults.standard.set(true, forKey: "upcomingTabVisible")
        }
        
        // 设置约束
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - TableView代理方法
extension UserProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 3 : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        // 重置cell
        cell.accessoryView = nil
        cell.accessoryType = .none
        cell.textLabel?.textColor = .label
        
        // 移除之前可能添加的标签
        for subview in cell.contentView.subviews {
            subview.removeFromSuperview()
        }
        
        if indexPath.section == 0 {
            // 第一组显示账户信息
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "用户名"
                cell.accessoryType = .disclosureIndicator
            case 1:
                cell.textLabel?.text = "邮箱"
                cell.accessoryType = .disclosureIndicator
            case 2:
                cell.textLabel?.text = "设置"
                cell.accessoryType = .disclosureIndicator
            default:
                break
            }
        } else {
            // 第二组显示底部导航栏设置
            cell.textLabel?.text = "底部导航栏显示（Upcoming）"
            
            // 创建并添加可选按钮
            let switchView = UISwitch()
            // 读取当前状态
            switchView.isOn = UserDefaults.standard.bool(forKey: "upcomingTabVisible")
            switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            
            // 添加Upcoming标签
            let detailLabel = UILabel()
            detailLabel.text = "upcoming"
            detailLabel.textColor = .gray
            detailLabel.font = .systemFont(ofSize: 14)
            
            cell.contentView.addSubview(detailLabel)
            detailLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                detailLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                detailLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -60)
            ])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc private func switchChanged(_ sender: UISwitch) {
        // 保存设置
        UserDefaults.standard.set(sender.isOn, forKey: "upcomingTabVisible")
        UserDefaults.standard.synchronize() // 立即同步设置
        print("用户切换开关: \(sender.isOn ? "打开" : "关闭") Upcoming标签")
        
        // 发送通知让MainTabBarViewController更新UI
        NotificationCenter.default.post(
            name: Notification.Name("upcomingTabVisibilityChanged"),
            object: nil,
            userInfo: ["isVisible": sender.isOn]
        )
        
        // 我们不再在这里直接操作TabBarController，而是完全依赖通知机制
        // 这样可以避免重复更新UI和可能的冲突
    }
    
    // 创建UpcomingViewController的方法
    private func createUpcomingViewController() -> UIViewController {
        // 创建一个完整的UpcomingViewController
        let upcomingVC = RealUpcomingViewController()
        upcomingVC.view.backgroundColor = .systemBackground
        upcomingVC.title = "Upcoming"
        return upcomingVC
    }
}

// 实现一个真正的UpcomingViewController
class RealUpcomingViewController: UIViewController {
    
    private var titles: [Any] = []
    
    private let upcomingTable: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Upcoming"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        
        // 添加tableView
        view.addSubview(upcomingTable)
        upcomingTable.delegate = self
        upcomingTable.dataSource = self
        
        // 获取数据
        fetchUpcoming()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        upcomingTable.frame = view.bounds
    }
    
    private func fetchUpcoming() {
        // 这里可以添加获取即将上映电影的网络请求
        // 但是现在我们只添加一些假数据
        DispatchQueue.main.async { [weak self] in
            // 创建测试数据 - 使用字典而不是Title模型
            self?.titles = [
                ["title": "Upcoming Movie 1", "overview": "This is movie 1"],
                ["title": "Upcoming Movie 2", "overview": "This is movie 2"],
                ["title": "Upcoming Movie 3", "overview": "This is movie 3"]
            ]
            self?.upcomingTable.reloadData()
        }
    }
}

// 扩展RealUpcomingViewController实现表格视图代理和数据源方法
extension RealUpcomingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if let titleDict = titles[indexPath.row] as? [String: String] {
            cell.textLabel?.text = titleDict["title"] ?? "Unknown"
        } else {
            cell.textLabel?.text = "Unknown"
        }
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // 这里可以添加点击行的处理逻辑
    }
}
