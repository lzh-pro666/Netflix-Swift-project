//
//  TitleTableViewCell.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/4/12.
//

import UIKit

class TitleTableViewCell: UITableViewCell {

    // 定义 cell 的标识
    static let identifier = "TitleTableViewCell"
    
    // 创建一个标签
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0 // 0 表示多行
        return label
    }()
    
    // 创建一个 播放button
    private let playTitleButton: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "play.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30))
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .label
        return button
    }()
    
    // 创建 image 视图
    private let titlePosterUIImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // 设置圆角
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        // 添加边框效果
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        // 设置背景色作为占位图
        imageView.backgroundColor = .systemGray5
        // 防止图片溢出容器
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // 添加占位视图
    private let placeholderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        
        // 添加占位图标
        let imageView = UIImageView(image: UIImage(systemName: "photo"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // 居中图标
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 30),
            imageView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return view
    }()
    
    // 添加视频ID属性
    private var videoID: Int?
    
    // 添加播放按钮点击处理的回调
    var playButtonTapHandler: (() -> Void)?
    
    // 重写初始化
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(placeholderView)
        contentView.addSubview(titlePosterUIImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(playTitleButton)
        
        // 添加播放按钮点击事件
        playTitleButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        
        applyConstraints()
    }
    
    // 添加 cell 的约束
    private func applyConstraints(){
        let placeholderViewConstraints = [
            placeholderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            placeholderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            placeholderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            placeholderView.widthAnchor.constraint(equalToConstant: 100)
        ]
        
        let titlesPosterUIImageViewConstraints = [
            titlePosterUIImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            titlePosterUIImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titlePosterUIImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            titlePosterUIImageView.widthAnchor.constraint(equalToConstant: 100)
        ]
        let titleLabelConstrainsts = [
            titleLabel.leadingAnchor.constraint(equalTo: titlePosterUIImageView.trailingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 210)
        ]
        let playTitleButtonConstrainsts = [
            playTitleButton.leadingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -50),
            playTitleButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ]
        NSLayoutConstraint.activate(placeholderViewConstraints)
        NSLayoutConstraint.activate(titlesPosterUIImageViewConstraints)
        NSLayoutConstraint.activate(titleLabelConstrainsts)
        NSLayoutConstraint.activate(playTitleButtonConstrainsts)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 重置图片和显示状态
        titlePosterUIImageView.image = nil
        placeholderView.isHidden = false
    }
    
    // 处理播放按钮点击
    @objc private func playButtonTapped() {
        playButtonTapHandler?()
    }
    
    // 定义配置
    public func configure(with model: TitleViewModel){
        guard let url = URL(string: "https://image.tmdb.org/t/p/w500\(model.posterURL)") else {
            return
        }
        
        // 保存视频ID
        if let id = model.id {
            self.videoID = id
        }
        
        // 显示占位图
        placeholderView.isHidden = false
        
        // 加载图片并在完成时隐藏占位图
        titlePosterUIImageView.sd_setImage(with: url) { [weak self] (image, error, cacheType, url) in
            // 加载成功后隐藏占位图
            if image != nil {
                self?.placeholderView.isHidden = true
            }
        }
        
        titleLabel.text = model.titleName
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

}
