//
//  ViewController.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/3/10.
//

import UIKit

// 定义通知名称
extension Notification.Name {
    static let upcomingTabVisibilityChanged = Notification.Name("upcomingTabVisibilityChanged")
}

// 使用已存在的UserDefaultsManager类

class MainTabBarViewController: UITabBarController {
    
    // 缓存各个视图控制器
    private var homeVC: UINavigationController!
    private var upcomingVC: UINavigationController!
    private var shortsVC: UINavigationController!
    private var searcherVC: UINavigationController!
    private var downloadVC: UINavigationController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 避免 TabBar 透明覆盖内容
        tabBar.isTranslucent = false
        tabBar.backgroundColor = UIColor.clear
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()

        // 设置默认值（如果没有设置过）
        if UserDefaultsManager.shared.isUpcomingTabVisible() == false && UserDefaults.standard.object(forKey: "upcomingTabVisible") == nil {
            UserDefaultsManager.shared.setUpcomingTabVisible(true)
        }
        
        // 先初始化各个导航栏控制器
        setupViewControllers()
        
        // 基本的标签设置（确保初始状态至少有基本视图控制器）
        setViewControllers([homeVC, upcomingVC, shortsVC, searcherVC, downloadVC], animated: false)
        
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
        shortsVC = UINavigationController(rootViewController: ShortsViewController())
        searcherVC = UINavigationController(rootViewController: SearcherViewController())
        downloadVC = UINavigationController(rootViewController: DownloadViewController())
        
        //设置图标和名称
        homeVC.tabBarItem.image = UIImage(systemName: "house.circle.fill")
        upcomingVC.tabBarItem.image = UIImage(systemName: "play.circle")
        shortsVC.tabBarItem.image = UIImage(systemName: "video.circle")
        searcherVC.tabBarItem.image = UIImage(systemName: "magnifyingglass.circle")
        downloadVC.tabBarItem.image = UIImage(systemName: "arrowshape.down.circle")
        
        homeVC.title = "Home"
        upcomingVC.title = "Upcoming"
        shortsVC.title = "Shorts"
        searcherVC.title = "Top Search"
        downloadVC.title = "DownLoad"
        
        //设置选中 tabbar 的颜色
        tabBar.tintColor = .label
    }
    
    @objc private func updateTabBarItems(_ notification: Notification? = nil) {
        // 从UserDefaultsManager获取可见状态
        let showUpcoming = UserDefaultsManager.shared.isUpcomingTabVisible()
        print("更新标签栏，显示Upcoming: \(showUpcoming), 当前视图控制器数量: \(viewControllers?.count ?? 0)")
        
        // 确保所有视图控制器都已初始化且非空
        guard let homeVC = self.homeVC,
              let upcomingVC = self.upcomingVC,
              let shortsVC = self.shortsVC,
              let searcherVC = self.searcherVC,
              let downloadVC = self.downloadVC else {
            print("视图控制器尚未初始化，无法更新标签栏")
            return
        }
        
        // 简化更新逻辑，直接设置
        if showUpcoming {
            // 显示所有标签页（包括Upcoming）
            if (viewControllers?.count != 5) || (viewControllers?[1] !== upcomingVC) {
                print("设置带Upcoming的标签栏")
                let newViewControllers: [UIViewController] = [homeVC, upcomingVC, shortsVC, searcherVC, downloadVC]
                setViewControllers(newViewControllers, animated: false)
            }
        } else {
            // 不显示Upcoming标签
            if (viewControllers?.count != 4) || (viewControllers?[0] !== homeVC) {
                print("设置不带Upcoming的标签栏")
                let newViewControllers: [UIViewController] = [homeVC, shortsVC, searcherVC, downloadVC]
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

