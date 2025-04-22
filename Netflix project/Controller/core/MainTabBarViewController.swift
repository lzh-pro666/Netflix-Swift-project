//
//  ViewController.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/4/10.
//

import UIKit

// 定义通知名称
extension Notification.Name {
    static let upcomingTabVisibilityChanged = Notification.Name("upcomingTabVisibilityChanged")
}

// 在文件内实现UserDefaultsManager避免导入问题
class UserDefaultsManager {
    
    static let shared = UserDefaultsManager()
    
    private let upcomingTabVisibleKey = "upcomingTabVisible"
    
    private init() {}
    
    // 设置upcoming标签是否可见
    func setUpcomingTabVisible(_ visible: Bool) {
        UserDefaults.standard.set(visible, forKey: upcomingTabVisibleKey)
    }
    
    // 获取upcoming标签是否可见
    func isUpcomingTabVisible() -> Bool {
        // 默认为true，如果未设置则返回true
        return UserDefaults.standard.bool(forKey: upcomingTabVisibleKey)
    }
}

class MainTabBarViewController: UITabBarController {
    
    // 缓存各个视图控制器
    private var homeVC: UINavigationController!
    private var upcomingVC: UINavigationController!
    private var searcherVC: UINavigationController!
    private var downloadVC: UINavigationController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置默认值（如果没有设置过）
        if UserDefaults.standard.object(forKey: "upcomingTabVisible") == nil {
            UserDefaults.standard.set(true, forKey: "upcomingTabVisible")
        }
        
        // 先初始化各个导航栏控制器
        setupViewControllers()
        
        // 基本的标签设置（确保初始状态至少有基本视图控制器）
        setViewControllers([homeVC, upcomingVC, searcherVC, downloadVC], animated: false)
        
        // 然后根据用户设置更新标签栏
        DispatchQueue.main.async {
            self.updateTabBarItems()
        }
        
        // 注册通知观察者以便在设置更改时更新标签栏
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(updateTabBarItems), 
            name: .upcomingTabVisibilityChanged, 
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 移除旧的观察者
        NotificationCenter.default.removeObserver(self, name: .upcomingTabVisibilityChanged, object: nil)
        
        // 重新注册通知观察者
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(updateTabBarItems), 
            name: .upcomingTabVisibilityChanged, 
            object: nil
        )
    }
    
    private func setupViewControllers() {
        //在标签栏中添加各个导航栏控制器
        homeVC = UINavigationController(rootViewController: HomeViewController())
        upcomingVC = UINavigationController(rootViewController: UpcomingViewController())
        searcherVC = UINavigationController(rootViewController: SearcherViewController())
        downloadVC = UINavigationController(rootViewController: DownloadViewController())
        
        //设置图标和名称
        homeVC.tabBarItem.image = UIImage(systemName: "house.circle.fill")
        upcomingVC.tabBarItem.image = UIImage(systemName: "play.circle")
        searcherVC.tabBarItem.image = UIImage(systemName: "magnifyingglass.circle")
        downloadVC.tabBarItem.image = UIImage(systemName: "arrowshape.down.circle")
        
        homeVC.title = "Home"
        upcomingVC.title = "Upcoming"
        searcherVC.title = "Top Search"
        downloadVC.title = "DownLoad"
        
        //设置选中 tabbar 的颜色
        tabBar.tintColor = .label
    }
    
    @objc private func updateTabBarItems(_ notification: Notification? = nil) {
        // 从UserDefaults获取可见状态
        let showUpcoming = UserDefaults.standard.bool(forKey: "upcomingTabVisible")
        print("更新标签栏，显示Upcoming: \(showUpcoming), 当前视图控制器数量: \(viewControllers?.count ?? 0)")
        
        // 确保所有视图控制器都已初始化且非空
        guard let homeVC = self.homeVC,
              let upcomingVC = self.upcomingVC,
              let searcherVC = self.searcherVC,
              let downloadVC = self.downloadVC else {
            print("视图控制器尚未初始化，无法更新标签栏")
            return
        }
        
        // 简化更新逻辑，直接设置
        if showUpcoming {
            // 显示所有标签页（包括Upcoming）
            if (viewControllers?.count != 4) || (viewControllers?[1] !== upcomingVC) {
                print("设置带Upcoming的标签栏")
                let newViewControllers: [UIViewController] = [homeVC, upcomingVC, searcherVC, downloadVC]
                setViewControllers(newViewControllers, animated: false)
            }
        } else {
            // 不显示Upcoming标签
            if (viewControllers?.count != 3) || (viewControllers?[0] !== homeVC) {
                print("设置不带Upcoming的标签栏")
                let newViewControllers: [UIViewController] = [homeVC, searcherVC, downloadVC]
                setViewControllers(newViewControllers, animated: false)
            }
        }
        
        // 强制更新布局
        tabBar.setNeedsLayout()
        tabBar.layoutIfNeeded()
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    // 在视图控制器被释放时移除通知观察者
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

