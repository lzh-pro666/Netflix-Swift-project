//
//  TitleCollectionViewCell.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/4/11.
//

import Foundation
import SDWebImage
/*
 构建 cell的一种代码范式：
 1、定义单元格类
 2、设置静态标识符，用于注册和复用单元格
 3、添加子视图到 contentview
 4、配置布局
 5、提供配置方法
 */
class TitleCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "TitleCollectionViewCell"

    private let posterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.backgroundColor = .systemGray5
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let placeholderView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.lightGray.cgColor
        
        let imageView = UIImageView(image: UIImage(systemName: "photo"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 30),
            imageView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(placeholderView)
        contentView.addSubview(posterImageView)
    }
    // 表示不支持从xib和storybord 加载
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        // 用于在单元格布局发生变化时更新子视图的位置
        super.layoutSubviews()
        placeholderView.frame = contentView.bounds
        posterImageView.frame = contentView.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 重置图片和显示状态
        posterImageView.image = nil
        placeholderView.isHidden = false
    }
    
    // 接受一个字符串（图片 URL），使用 SDWebImage 异步加载图片。
    public func configure(with model: String){
        guard let url = URL(string: "https://image.tmdb.org/t/p/w500\(model)") else {
            return
        }
        
        // 显示占位图
        placeholderView.isHidden = false
        
        // 加载图片并在完成时隐藏占位图
        posterImageView.sd_setImage(with: url) { [weak self] (image, error, cacheType, url) in
            // 加载成功后隐藏占位图
            if image != nil {
                self?.placeholderView.isHidden = true
            }
        }
    }
}
