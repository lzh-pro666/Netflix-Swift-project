//
//  TitlePreviewViewController.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/4/14.
//

import UIKit
import WebKit

class DownloadPreviewViewController: UIViewController {

    // 设置展示的 web 视图
    private let webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(webView)

        configureConstraints()
        
        // Do any additional setup after loading the view.
    }
    
    func configureConstraints(){
        let webViewConstraints = [
            webView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor),
            webView.heightAnchor.constraint(equalToConstant: 300)
        ]
       
        NSLayoutConstraint.activate(webViewConstraints)
    }
    func configure(with model: DownloadPreviewViewModel){

        guard let url = URL(string: "\(model.pexelsView.url)") else {
            return
        }
        webView.load(URLRequest(url: url))
    }
}
