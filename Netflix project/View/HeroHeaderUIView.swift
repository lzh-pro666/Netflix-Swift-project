//
//  HeroHeaderUIView.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/4/10.
//

import UIKit

class HeroHeaderUIView: UIView {
    
    private let heroImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        // 添加圆角效果
        imageView.layer.cornerRadius = 5
        imageView.layer.masksToBounds = true
        // 添加边框效果
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        // 设置默认背景色作为占位图
        imageView.backgroundColor = .systemGray5
        return imageView
    }()
    
    // 添加占位视图
    private let placeholderView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        
        // 添加播放图标
        let playImageView = UIImageView(image: UIImage(systemName: "play.circle"))
        playImageView.translatesAutoresizingMaskIntoConstraints = false
        playImageView.tintColor = .white
        playImageView.contentMode = .scaleAspectFit
        view.addSubview(playImageView)
        
        // 居中播放图标
        NSLayoutConstraint.activate([
            playImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playImageView.widthAnchor.constraint(equalToConstant: 80),
            playImageView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        return view
    }()
    
    private let playButton: UIButton = {
        let button = UIButton()
        button.setTitle("play", for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()
    
    private let downLoadButton: UIButton = {
        let button = UIButton()
        button.setTitle("download", for: .normal)
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // 添加图片渐变方法
    private func addGradient(){
        let gradientLayer = CAGradientLayer()
        // .cgColor将 uicolor 转化为 cgcolor
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.systemBackground.cgColor
        ]
        gradientLayer.frame = bounds
        layer.addSublayer(gradientLayer)
        
    }
    
    // 添加按钮控件约束
    private func applyconstraints(){
        
        let playButtonConstraints = [
            playButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 70),
            playButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50),
            playButton.widthAnchor.constraint(equalToConstant: 100),
            playButton.heightAnchor.constraint(equalToConstant: 40)  // 高度 40 点
        ]
        
        let downLoadButtonConstraints = [
            downLoadButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -70),
            downLoadButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50),
            downLoadButton.widthAnchor.constraint(equalToConstant: 100),
            downLoadButton.heightAnchor.constraint(equalToConstant: 40)  // 高度 40 点
        ]
        NSLayoutConstraint.activate(playButtonConstraints)
        NSLayoutConstraint.activate(downLoadButtonConstraints)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        placeholderView.frame = bounds
        heroImageView.frame = bounds
    }
    
    public func configure(with model:TitleViewModel){
        guard let url = URL(string: "https://image.tmdb.org/t/p/w500\(model.posterURL)") else {
            return
        }
        
        // 显示占位图
        placeholderView.isHidden = false
        
        // 加载图片，完成后隐藏占位图
        heroImageView.sd_setImage(with: url) { [weak self] (image, error, cacheType, url) in
            // 加载成功后隐藏占位图
            if image != nil {
                self?.placeholderView.isHidden = true
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(placeholderView)
        addSubview(heroImageView)
        addGradient()
        addSubview(playButton)
        addSubview(downLoadButton)
        
        applyconstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    


}
