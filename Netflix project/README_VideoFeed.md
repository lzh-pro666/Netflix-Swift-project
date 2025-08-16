# Netflix 项目 - 视频 Feed 功能说明

## 概述

本项目新增了一个类似 TikTok 的视频 feed 播放功能，使用 Texture + IGListKit 实现垂直滚动的视频 feed，支持视频预加载、缓存管理和性能监控。

## 技术架构

### 核心框架
- **Texture (AsyncDisplayKit)**: 用于高性能的异步 UI 渲染
- **IGListKit**: 用于列表数据管理和性能优化
- **CachingPlayerItem**: 用于视频缓存和预加载
- **AVFoundation**: 用于视频播放控制

### 主要组件
1. **VideoFeedModel**: 视频数据模型
2. **VideoFeedCell**: 视频播放单元格
3. **ShortsViewController**: 视频 feed 主控制器
4. **VideoPlaybackManager**: 视频播放管理器
5. **VideoCacheManager**: 视频缓存管理器
6. **NetworkMonitor**: 网络状态监控器
7. **PerformanceMonitor**: 性能监控器

## 功能特性

### 🎥 视频播放
- 垂直滚动的视频 feed
- 自动播放/暂停（可见性控制）
- 循环播放
- 点击播放/暂停

### 🚀 性能优化
- 视频预加载机制
- 内存缓存管理
- 滚动性能优化
- 帧率监控

### 🌐 网络适应
- 网络状态检测
- 网络类型识别（WiFi/蜂窝/有线）
- 网络费用感知
- 自适应视频质量

### 📊 性能监控
- FPS 监控
- 内存使用监控
- CPU 使用率监控
- 滚动帧丢失检测
- 视频加载时间统计
- 播放卡顿检测

## 安装和设置

### 1. 依赖框架

项目已配置以下 Pod 依赖：

```ruby
pod 'Texture'
pod 'IGListKit'
pod 'CachingPlayerItem'
pod 'SDWebImage'
```

### 2. Xcode 设置

#### 权限设置
在 `Info.plist` 中添加以下权限：

```xml
<!-- 网络权限 -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>

<!-- 本地网络权限 -->
<key>NSLocalNetworkUsageDescription</key>
<string>用于视频缓存和预加载</string>
```

#### 后台模式
在项目设置中启用后台模式：
- Audio, AirPlay, and Picture in Picture
- Background fetch
- Background processing

#### 设备方向
建议设置为仅支持竖屏：
- Portrait
- Upside Down

### 3. 视频资源

当前使用本地测试视频，位于 `video test/` 文件夹：
- `6e170e3a5049f23262a20cdc21ec5c88.mp4`
- `4357d557bf638a5eb14a6a4c301acf37.mp4`
- `308407c240ca8bf58b030f214feeae78.mp4`

## 使用方法

### 1. 基本使用

```swift
// 创建视频 feed 控制器
let shortsVC = ShortsViewController()
let navigationController = UINavigationController(rootViewController: shortsVC)

// 添加到标签栏
tabBarController?.viewControllers?.append(navigationController)
```

### 2. 视频播放控制

```swift
// 播放指定索引的视频
shortsVC.playVideo(at: 0)

// 暂停当前视频
shortsVC.pauseCurrentVideo()

// 跳转到指定视频
shortsVC.jumpToVideo(at: 2)

// 预加载下一个视频
shortsVC.preloadNextVideo()
```

### 3. 性能监控

```swift
// 启动性能监控
PerformanceMonitor.shared.startMonitoring()

// 获取性能报告
let report = PerformanceMonitor.shared.getPerformanceReport()
print(report)

// 设置性能警告回调
PerformanceMonitor.shared.onPerformanceWarning = { warning in
    print("性能警告: \(warning)")
}
```

### 4. 网络监控

```swift
// 获取当前网络状态
let (isConnected, type, isExpensive) = NetworkMonitor.shared.getCurrentNetworkInfo()

// 设置网络状态变化回调
NetworkMonitor.shared.onNetworkStatusChanged = { isConnected, type in
    if isConnected {
        print("网络已连接: \(type?.description ?? "unknown")")
    } else {
        print("网络已断开")
    }
}
```

## 性能测试

### 测试项目

1. **滚动性能测试**
   - 快速上下滚动
   - 观察 FPS 变化
   - 检查是否有卡顿

2. **跳转性能测试**
   - 使用 `jumpToVideo` 方法跳转
   - 观察跳转速度
   - 检查视频加载时间

3. **网络切换测试**
   - WiFi 和蜂窝网络切换
   - 观察预加载行为变化
   - 检查视频质量调整

4. **内存压力测试**
   - 长时间使用应用
   - 观察内存使用情况
   - 检查缓存清理机制

### 性能指标

- **目标 FPS**: 60fps
- **内存使用**: < 500MB
- **视频加载时间**: < 3秒
- **滚动帧丢失**: < 10帧/分钟

## 自定义配置

### 1. 视频缓存设置

```swift
// 修改缓存大小
VideoCacheManager.shared.maxCacheSize = 20 // 最大缓存 20 个视频
VideoCacheManager.shared.maxCacheMemory = 200 * 1024 * 1024 // 200MB
```

### 2. 预加载策略

```swift
// 修改预加载数量
VideoPlaybackManager.shared.maxPreloadCount = 5 // 预加载 5 个视频
```

### 3. 性能监控频率

```swift
// 修改监控频率
PerformanceMonitor.shared.monitoringInterval = 0.5 // 每 0.5 秒监控一次
```

## 故障排除

### 常见问题

1. **视频无法播放**
   - 检查视频文件路径
   - 确认文件格式支持
   - 检查权限设置

2. **性能问题**
   - 查看控制台性能警告
   - 检查内存使用情况
   - 调整缓存设置

3. **网络问题**
   - 检查网络权限
   - 确认网络状态
   - 查看网络监控日志

### 调试技巧

1. **启用详细日志**
   ```swift
   // 在 AppDelegate 中设置
   #if DEBUG
   print("调试模式已启用")
   #endif
   ```

2. **性能报告**
   ```swift
   let report = PerformanceMonitor.shared.getPerformanceReport()
   print(report)
   ```

3. **网络状态检查**
   ```swift
   let networkInfo = NetworkMonitor.shared.getCurrentNetworkInfo()
   print("网络状态: \(networkInfo)")
   ```

## 后续扩展

### 1. 网络视频支持
- 集成 HLS/ABR 视频源
- 添加 CDN 支持
- 实现自适应码率

### 2. 社交功能
- 点赞、评论、分享
- 用户关注系统
- 内容推荐算法

### 3. 高级播放功能
- 倍速播放
- 画中画模式
- 后台播放

### 4. 数据分析
- 用户行为分析
- 播放数据统计
- 性能数据上报

## 技术支持

如有问题或建议，请查看：
1. 控制台日志输出
2. 性能监控报告
3. 网络状态信息
4. 相关框架文档

---

**注意**: 本功能目前使用本地测试视频，生产环境中需要替换为真实的网络视频源和相应的网络请求逻辑。
