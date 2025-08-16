//
//  TitlePreviewViewController.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/3/14.
//

import UIKit
import WebKit

class TitlePreviewViewController: UIViewController {

    // 设置标题标签
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 22, weight: .bold)
        return label
    }()
    
    // 设置简介标签
    private let overviewLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        // 表示允许文本根据内容自动换行，适合显示动态或长文本
        label.numberOfLines = 0
        return label
    }()
    
    // 设置下载按钮
    private let downLoadButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .red
        button.setTitle("DownLoad", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        return button
    }()
    
    // 设置展示的 web 视图
    private let webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        // 设置背景色和圆角
        webView.backgroundColor = .lightGray
        webView.layer.cornerRadius = 5
        webView.layer.masksToBounds = true
        return webView
    }()
    
    // 添加占位视图
    private let placeholderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
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
            playImageView.widthAnchor.constraint(equalToConstant: 50),
            playImageView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置导航栏
        configureNavigationBar()
        
        view.addSubview(placeholderView) // 先添加占位视图
        view.addSubview(webView)
        view.addSubview(titleLabel)
        view.addSubview(overviewLabel)
        view.addSubview(downLoadButton)
        
        configureConstraints()
        view.alpha = 0 // 初始时隐藏视图
        
        // 初始时显示占位图，加载完成后隐藏
        webView.navigationDelegate = self
        placeholderView.isHidden = false
        webView.alpha = 0
    }
    
    private func configureNavigationBar() {
        // 确保导航栏可见
        navigationController?.navigationBar.isHidden = false
        // 设置导航栏标题模式
        navigationItem.largeTitleDisplayMode = .never
        // 自定义返回按钮 - 白色加粗
        if navigationController?.viewControllers.count ?? 0 > 1 {
            let backButton = UIBarButtonItem(
                image: UIImage(systemName: "chevron.backward")?.withTintColor(.white, renderingMode: .alwaysOriginal),
                style: .plain,
                target: self,
                action: #selector(backButtonTapped)
            )
            // 使按钮更粗
            let fontAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17)]
            backButton.setTitleTextAttributes(fontAttributes, for: .normal)
            backButton.tintColor = .white
            
            navigationItem.leftBarButtonItem = backButton
        }
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 在视图即将显示时确保导航栏已恢复正常状态
        navigationController?.navigationBar.transform = .identity
        // 在动画即将完成时显示内容
        UIView.animate(withDuration: 0.3) {
            self.view.alpha = 1
        }
    }
    
    func configureConstraints(){
        let placeholderViewConstraints = [
            placeholderView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            placeholderView.leftAnchor.constraint(equalTo: view.leftAnchor),
            placeholderView.rightAnchor.constraint(equalTo: view.rightAnchor),
            placeholderView.heightAnchor.constraint(equalToConstant: 300)
        ]
        
        let webViewConstraints = [
            webView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor),
            webView.heightAnchor.constraint(equalToConstant: 300)
        ]
        let titleLabelConstraints = [
            titleLabel.topAnchor.constraint(equalTo: webView.bottomAnchor, constant: 20),
            titleLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            titleLabel.rightAnchor.constraint(equalTo: view.rightAnchor)
        ]
        let overviewLabelConstraints = [
            overviewLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            overviewLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            overviewLabel.rightAnchor.constraint(equalTo: view.rightAnchor)
        ]
        let downloadButtonConstraints = [
            downLoadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            downLoadButton.topAnchor.constraint(equalTo: overviewLabel.bottomAnchor, constant: 25),
            downLoadButton.widthAnchor.constraint(equalToConstant: 140),
            downLoadButton.heightAnchor.constraint(equalToConstant: 40)
        ]
        
        NSLayoutConstraint.activate(placeholderViewConstraints)
        NSLayoutConstraint.activate(webViewConstraints)
        NSLayoutConstraint.activate(titleLabelConstraints)
        NSLayoutConstraint.activate(overviewLabelConstraints)
        NSLayoutConstraint.activate(downloadButtonConstraints)
    }
    func configure(with model: TitlePreviewViewModel){
        titleLabel.text = model.title
        overviewLabel.text = model.titleOverview
        
        guard let url = URL(string: "https://www.youtube.com/embed/\(model.youtubeView.id.videoId ?? "")") else {
            return
        }
        webView.load(URLRequest(url: url))
    }
}

// 添加WKNavigationDelegate协议
extension TitlePreviewViewController: WKNavigationDelegate {
    // webView加载完成
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // 隐藏占位图，显示webView
        UIView.animate(withDuration: 0.3) {
            self.placeholderView.alpha = 0
            self.webView.alpha = 1
        } completion: { _ in
            self.placeholderView.isHidden = true
        }
    }
    
    // webView加载失败
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // 保持显示占位图
        placeholderView.isHidden = false
        webView.alpha = 0
    }
}
