
source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'

# 全局平台版本
platform :ios, '14.0'

target 'Netflix project' do
  # 使用动态 frameworks（Swift 必需）
  use_frameworks!

  # Pod 依赖列表
  # 固定 Texture 版本，避免 CDN 下载失败
  pod 'Texture'
  pod 'IGListKit'
  pod 'CachingPlayerItem'
  pod 'SDWebImage'
end

# 统一提升 Pods 的最低部署版本，避免 Xcode 关于支持范围 (< 14.0) 的编译告警
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      current = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
      if current.nil? || current.to_f < 14.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      end
    end
  end
end
