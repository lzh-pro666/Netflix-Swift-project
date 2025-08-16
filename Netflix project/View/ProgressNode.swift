import UIKit
import AsyncDisplayKit

// MARK: - 自绘进度条节点
class ProgressNode: ASDisplayNode {
    
    // MARK: - 属性
    private var progress: CGFloat = 0.0
    private var isDragging: Bool = false
    private var panGesture: UIPanGestureRecognizer?
    private var thumbPosition: CGFloat = 0.0
    
    // MARK: - 样式配置
    private let trackHeight: CGFloat = 6.0
    private let thumbWidth: CGFloat = 12.0
    private let thumbHeight: CGFloat = 16.0
    private var thumbHalfWidth: CGFloat { thumbWidth / 2.0 }
    private let trackColor = UIColor.systemGray4  // 默认浅灰
    private let progressColor = UIColor.systemGray // 已播放更深的灰
    private let thumbColor = UIColor.systemYellow  // 保持黄色，形状改为矩形
    private let activeThumbColor = UIColor.systemOrange
    
    // MARK: - 回调
    var onProgressChanged: ((CGFloat) -> Void)?
    var onDragBegan: (() -> Void)?
    var onDragEnded: ((CGFloat) -> Void)?
    
    // MARK: - 初始化
    override init() {
        super.init()
        setupNode()
    }
    
    private func setupNode() {
        // 启用用户交互
        isUserInteractionEnabled = true
        
        // 设置背景透明
        backgroundColor = .clear
        
        // 确保节点为非不透明，避免底部出现不必要的黑色背景
        isOpaque = false
        
        // 自定义绘制（开启异步绘制）
        displaysAsynchronously = true
        
        // 手势需要在节点 view 加载完成后（主线程）添加
        // 将原先的 setupGestureRecognizers() 调用移动到 didLoad 中
    }
    
    override func didLoad() {
        super.didLoad()
        // didLoad 在主线程调用，此时可以安全访问 view
        setupGestureRecognizers()
    }
    
    private func setupGestureRecognizers() {
        // 添加 Pan 手势用于拖动
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture?.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture!)
        
        // 添加 Tap 手势用于点击跳转
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - 公共方法
    func setProgress(_ progress: CGFloat, animated: Bool = false) {
        let clampedProgress = max(0.0, min(1.0, progress))
        
        if animated {
            let animation = CABasicAnimation(keyPath: "progress")
            animation.fromValue = self.progress
            animation.toValue = clampedProgress
            animation.duration = 0.2
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(animation, forKey: "progressAnimation")
        }
        
        self.progress = clampedProgress
        updateThumbPosition()
        setNeedsDisplay()
    }
    
    private func updateThumbPosition() {
        let trackWidth = bounds.width - thumbWidth
        thumbPosition = thumbHalfWidth + trackWidth * progress
    }
    
    // MARK: - 绘制
    override func drawParameters(forAsyncLayer layer: _ASDisplayLayer) -> NSObjectProtocol? {
        return ProgressDrawingParameters(
            bounds: bounds,
            progress: progress,
            isDragging: isDragging,
            thumbPosition: thumbPosition,
            trackHeight: trackHeight,
            thumbWidth: thumbWidth,
            thumbHeight: thumbHeight,
            trackColor: trackColor,
            progressColor: progressColor,
            thumbColor: isDragging ? activeThumbColor : thumbColor
        )
    }
    
    override class func draw(_ bounds: CGRect, withParameters parameters: Any?, isCancelled isCancelledBlock: () -> Bool, isRasterizing: Bool) {
        guard let params = parameters as? ProgressDrawingParameters else { return }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setAllowsAntialiasing(true)
        
        // 绘制轨道背景（浅灰，圆角矩形）
        let trackY = bounds.midY - params.trackHeight / 2
        let trackRect = CGRect(x: params.thumbWidth / 2,
                               y: trackY,
                               width: bounds.width - params.thumbWidth,
                               height: params.trackHeight)
        context?.setFillColor(params.trackColor.cgColor)
        let trackPath = UIBezierPath(roundedRect: trackRect, cornerRadius: params.trackHeight / 2)
        context?.addPath(trackPath.cgPath)
        context?.fillPath()
        
        // 绘制进度填充（深灰，圆角矩形）
        if params.progress > 0 {
            let progressWidth = (bounds.width - params.thumbWidth) * params.progress
            let progressRect = CGRect(x: params.thumbWidth / 2,
                                      y: trackY,
                                      width: progressWidth,
                                      height: params.trackHeight)
            context?.setFillColor(params.progressColor.cgColor)
            let progressPath = UIBezierPath(roundedRect: progressRect, cornerRadius: params.trackHeight / 2)
            context?.addPath(progressPath.cgPath)
            context?.fillPath()
        }
        
        // 绘制拖动手柄（黄色矩形，带圆角）
        let thumbCenterX = params.thumbPosition
        let thumbRect = CGRect(x: thumbCenterX - params.thumbWidth / 2,
                               y: bounds.midY - params.thumbHeight / 2,
                               width: params.thumbWidth,
                               height: params.thumbHeight)
        
        // 手柄阴影效果
        if params.isDragging {
            context?.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.3).cgColor)
        }
        
        context?.setFillColor(params.thumbColor.cgColor)
        let thumbPath = UIBezierPath(roundedRect: thumbRect, cornerRadius: 3)
        context?.addPath(thumbPath.cgPath)
        context?.fillPath()
        
        // 清除阴影
        context?.setShadow(offset: .zero, blur: 0, color: nil)
        
        // 拖动时绘制高亮外边框（与手柄同形状）
        if params.isDragging {
            let highlightRect = thumbRect.insetBy(dx: -3, dy: -3)
            context?.setStrokeColor(params.thumbColor.withAlphaComponent(0.3).cgColor)
            context?.setLineWidth(2)
            let highlightPath = UIBezierPath(roundedRect: highlightRect, cornerRadius: 4)
            context?.addPath(highlightPath.cgPath)
            context?.strokePath()
        }
    }
    
    // MARK: - 手势处理
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: view)
        
        switch gesture.state {
        case .began:
            isDragging = true
            onDragBegan?()
            updateProgressFromLocation(location)
            setNeedsDisplay()
            
        case .changed:
            updateProgressFromLocation(location)
            
        case .ended, .cancelled:
            isDragging = false
            onDragEnded?(progress)
            setNeedsDisplay()
            
        default:
            break
        }
    }
    
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        updateProgressFromLocation(location)
        onProgressChanged?(progress)
    }
    
    private func updateProgressFromLocation(_ location: CGPoint) {
        let trackWidth = bounds.width - thumbWidth
        let relativeX = location.x - thumbWidth / 2
        let newProgress = max(0.0, min(1.0, relativeX / trackWidth))
        
        progress = newProgress
        updateThumbPosition()
        setNeedsDisplay()
        
        onProgressChanged?(progress)
    }
    
    // MARK: - 布局
    override func layout() {
        super.layout()
        updateThumbPosition()
    }
    
    override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        let height = max(thumbHeight, trackHeight)
        return CGSize(width: constrainedSize.width, height: height + 8) // 额外的触摸区域
    }
}

// MARK: - 绘制参数
private class ProgressDrawingParameters: NSObject {
    let bounds: CGRect
    let progress: CGFloat
    let isDragging: Bool
    let thumbPosition: CGFloat
    let trackHeight: CGFloat
    let thumbWidth: CGFloat
    let thumbHeight: CGFloat
    let trackColor: UIColor
    let progressColor: UIColor
    let thumbColor: UIColor
    
    init(bounds: CGRect, progress: CGFloat, isDragging: Bool, thumbPosition: CGFloat,
         trackHeight: CGFloat, thumbWidth: CGFloat, thumbHeight: CGFloat, trackColor: UIColor,
         progressColor: UIColor, thumbColor: UIColor) {
        self.bounds = bounds
        self.progress = progress
        self.isDragging = isDragging
        self.thumbPosition = thumbPosition
        self.trackHeight = trackHeight
        self.thumbWidth = thumbWidth
        self.thumbHeight = thumbHeight
        self.trackColor = trackColor
        self.progressColor = progressColor
        self.thumbColor = thumbColor
    }
}