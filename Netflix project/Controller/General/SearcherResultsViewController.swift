//
//  SearcherResultsViewController.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/4/12.
//

import UIKit

protocol SearcherResultsViewControllerDeleage: AnyObject{
    func searcherResultsViewControllerDidTapItem(_ viewModel: TitlePreviewViewModel)
}

class SearcherResultsViewController: UIViewController {

    
    public var titles: [Title] = [Title]()
    // 定义searcherResultsCollectionView视图
    public weak var deleage: SearcherResultsViewControllerDeleage?
    
    public let searcherResultsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width / 3 - 10, height: 200)
        layout.minimumInteritemSpacing = 0
        let conllectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        conllectionView.register(TitleCollectionViewCell.self, forCellWithReuseIdentifier: TitleCollectionViewCell.identifier)
        return conllectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        view.addSubview(searcherResultsCollectionView)
        
        searcherResultsCollectionView.delegate = self
        searcherResultsCollectionView.dataSource = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        searcherResultsCollectionView.frame = view.bounds
    }
    
}
extension SearcherResultsViewController: UICollectionViewDelegate,UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return titles.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TitleCollectionViewCell.identifier, for: indexPath) as? TitleCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let title = titles[indexPath.row]
        cell.configure(with: title.poster_path ?? "")
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let title = titles[indexPath.row]
        let titleName = title.original_title ?? title.original_name ?? ""
        
        APICaller.shared.getMovie(with: titleName) {[weak self] result in
            switch result{
            case .success(let videoElement):
                self?.deleage?.searcherResultsViewControllerDidTapItem(TitlePreviewViewModel(title: titleName, youtubeView: videoElement, titleOverview: title.overview ?? ""))
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
