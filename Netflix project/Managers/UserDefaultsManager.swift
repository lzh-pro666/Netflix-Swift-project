//
//  UserDefaultsManager.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/4/15.
//

import Foundation

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
        // 默认为true
        return UserDefaults.standard.bool(forKey: upcomingTabVisibleKey)
    }
} 