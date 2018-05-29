//
//  CollectionViewController.swift
//  Netbility
//
//  Created by Stuart Levine on 10/9/15.
//  Copyright © 2015 Wildcatproductions. All rights reserved.
//

import UIKit

typealias RefreshControlHandler = (UIRefreshControl)->()

////
// The collection view added as a container view the ImgurViewController
//
class CollectionViewController: UICollectionViewController {

    private let reuseIdentifier = "ImageCell"

    var dataSource: [ImgurImage] = [ImgurImage]()
    var refreshControlHandler: RefreshControlHandler?
    var downloads = [IndexPath : NetworkEngineDataTask]()
    let refreshControl = UIRefreshControl()
    var totalImageCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.scrollsToTop = true
        self.collectionView?.register(ImageCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView?.dataSource = self
        self.collectionView?.delegate = self
        self.collectionView?.backgroundColor = .white

        loadDataSource()

        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }

        // Add refresh controll
        refreshControl.addTarget(self, action: #selector(CollectionViewController.refresh(_:)), for: .valueChanged)

        self.collectionView?.addSubview(refreshControl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)

        guard let imageCell = cell as? ImageCell else { return cell }

        let photoDetails = dataSource[indexPath.row]

        switch (photoDetails.downloadState){
            case .new:
                imageCell.loadingView.isHidden = false
                let imageTaskDownloader = NetworkEngineDataTask(taskType: .imageDownloadForCell(indexPath: indexPath, image: photoDetails))
                setupClosures(forCell: imageCell, downloadTask: imageTaskDownloader)
                imageTaskDownloader.startDataTask()
                downloads[indexPath] = imageTaskDownloader
            case .downloading:
                if imageCell.loadingView.isHidden {
                    imageCell.loadingView.isHidden = false
                    setupClosures(forCell: imageCell, downloadTask: downloads[indexPath])
                }
                imageCell.loadingView.percentComplete = photoDetails.percentComplete
            case .downloaded, .failed:
                imageCell.thumbnailView.image = photoDetails.thumbnail
                imageCell.loadingView.isHidden = true
                downloads[indexPath]?.session.finishTasksAndInvalidate()
                downloads.removeValue(forKey: indexPath)
                imageCell.setNeedsLayout()
        }

        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard isNetworkReachable else { return }

        let photoRecord = dataSource[indexPath.item]
        let controller = PhotoViewController(with: photoRecord, indexPath: indexPath)
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: Utilitiy Methods

    func loadDataSource() {
        if ImgurClient.user.isAuthenticated {
            ImgurClient.apiCall(with: .imageCount, onCompletion: { (response) in
                switch response {
                case .error(let error):
                    if let error = error {
                        print(error.localizedDescription)
                    }
                case .success(let dict):
                    if let dict = dict as? [String: Any], let count = dict["data"] as? Int {
                        self.totalImageCount = count
                        self.loadImages()
                    }
                }
            })
        }
    }

    func loadImages() {
        ImgurClient.apiCall(with: .images(page: 0), onCompletion: { (response) in
            switch response {
            case .error(let error):
                if let error = error {
                    print(error.localizedDescription)
                }
            case .success(let json):
                if let json = json as? [String: Any], let images = json["data"] as? [[String: Any]] {
                    var dataSource = [ImgurImage]()
                    for jsonImage in images {
                        guard
                            let imageData = try? JSONSerialization.data(withJSONObject: jsonImage, options: []),
                            let image = try? JSONDecoder().decode(ImgurImage.self, from: imageData) else { continue }
                        dataSource.append(image)
                    }
                    self.dataSource = dataSource
                    DispatchQueue.main.async {
                        self.collectionView?.reloadData()
                    }
                }
            }
        })
    }

    func setupClosures(forCell cell: ImageCell?, downloadTask: NetworkEngineDataTask?) {
        downloadTask?.imageDownloadForCellCompletionBlock = { [unowned self] (indexPath) in
            guard let indexPath = indexPath else { return }

            DispatchQueue.main.async(execute: { [weak self] in
                cell?.loadingView.isHidden = true
                self?.collectionView?.reloadItems(at: [indexPath])
            })
        }
        downloadTask?.progressBlock = { (percent) in
            DispatchQueue.main.async {
                cell?.loadingView.percentComplete = percent
            }
        }
    }

    @objc
    func refresh(_ refresh: UIRefreshControl) {
        refresh.endRefreshing()
        loadDataSource()
    }

    func addToDataSource(_ photo: ImgurImage?) {
        if let photo = photo {
            dataSource.insert(photo, at: 0)
            collectionView?.insertItems(at: [IndexPath(item: 0, section: 0)])
        }
    }
}

////
// The registered cell class for the UICollectionView
//
class ImageCell: UICollectionViewCell {

    let loadingViewPadding: CGFloat = 25
    var thumbnailView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    var backgroundImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .darkGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    var loadingView: LoadingView = {
        let view = LoadingView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(backgroundImageView)
        contentView.addSubview(loadingView)
        contentView.addSubview(thumbnailView)

        backgroundImageView.pinEdges(.all, to: contentView)
        loadingView.pinEdges(.all, to: contentView, topInset: loadingViewPadding, leftInset: loadingViewPadding, bottomInset: loadingViewPadding, rightInset: loadingViewPadding)
        thumbnailView.pinEdges(.all, to: contentView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        thumbnailView.image = nil
        loadingView.setNeedsLayout()
        loadingView.layoutIfNeeded()
    }
}

////
// Provide 3D Touch previewing
//
extension CollectionViewController: UIViewControllerPreviewingDelegate {

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        guard let indexPath = collectionView?.indexPathForItem(at: location) else { return nil }

        if let collectionView = collectionView, let cell = collectionView.cellForItem(at: indexPath) {
            let r = collectionView.convert(cell.frame, from: collectionView)
            previewingContext.sourceRect = r
        }

        let photoRecord = dataSource[indexPath.row]

        if photoRecord.downloadState == .downloaded {
            let controller = PhotoViewController(with: photoRecord, indexPath: indexPath)
            controller.delegate = self
            let navController = UINavigationController(rootViewController: controller)
            controller.navigationItem.leftBarButtonItem = controller.closeButton
            return navController
        }

        return nil
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.navigationController?.present(viewControllerToCommit, animated: true, completion: nil)
    }
}

extension CollectionViewController: PhotoViewControllerDelegate {

    func didDeletePhoto(_ viewController: PhotoViewController, photo: ImgurImage, at indexPath: IndexPath) {
        dataSource.remove(at: indexPath.item)
        DispatchQueue.main.async {
            self.collectionView?.deleteItems(at: [indexPath])
            viewController.dismissOrPop(animated: true, completion: nil)
        }
    }
}
