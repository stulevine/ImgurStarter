//
//  PhotoViewController.swift
//
//  Created by Stuart Levine on 2/12/17.
//  Copyright © 2017 Wildcatproductions. All rights reserved.
//
//  A Basic UIImage viewer with scrolling and zooming
//
//  Also provides a UIDocumentInteractionController to allow a user to export or share the photo
//
//  - Added the ability to delete user photos from Imgur 5/27/2018

import UIKit
import Foundation

protocol PhotoViewControllerDelegate : class {
    func didDeletePhoto(_ viewController: PhotoViewController, photo: ImgurImage, at indexPath: IndexPath)
}

class PhotoViewController: UIViewController {

    let toolbarHeight:CGFloat = 50
    weak var delegate: PhotoViewControllerDelegate?
    lazy var documentinteractionController: UIDocumentInteractionController = {
        let dic = UIDocumentInteractionController()
        dic.delegate = self
        return dic
    }()

    lazy var deleteButton: UIBarButtonItem = {
        let deleteButton = UIBarButtonItem(image: UIImage(named: "trashcan")?.withRenderingMode(.alwaysTemplate),
                                           style: UIBarButtonItemStyle.done,
                                           target: self,
                                           action: #selector(showDeletePhotoAlert(_:)))
        deleteButton.tintColor = .red
        deleteButton.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -50)
        return deleteButton
    }()
    lazy var toolBar: UIToolbar = {
        let toolBar = UIToolbar()
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.isTranslucent = true
        let leftFlexibaleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        toolBar.setItems([leftFlexibaleSpace, deleteButton], animated: true)

        return toolBar
    }()
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.gray
        scrollView.maximumZoomScale = 4.0

        return scrollView
    }()
    lazy var imageView: UIImageView = {
        let iView = UIImageView()
        iView.contentMode = .scaleAspectFit
        iView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        return iView
    }()
    lazy var actionButton: UIBarButtonItem = {
        let actionButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(handleActionButton(sender:)))

        return actionButton
    }()
    lazy var closeButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage.xImage(width: 25, color: .black), style: .plain, target: self, action: #selector(tappedCloseButton(_:)))
        return button
    }()
    var tempFileURL: URL? {
        let filename = "\(UUID()).jpg"
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let url = urls.first?.appendingPathComponent(filename) {
            return url
        }
        return nil
    }
    
    var imageToShow: UIImage? {
        didSet {
            if let image = imageToShow {
                self.imageView.image = image
                self.scrollView.setNeedsLayout()
                self.scrollView.layoutIfNeeded()
            }
        }
    }
    var photoRecord: ImgurImage
    var indexPath: IndexPath

    init(with photoRecord: ImgurImage, indexPath: IndexPath) {
        self.photoRecord = photoRecord
        self.indexPath = indexPath

        super.init(nibName: nil, bundle: nil)

        self.title = photoRecord.title.isEmpty ? "Imgur Photo" : photoRecord.title

        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChange(_:)), name: kReachabilityChangedName, object: nil)

        setupTapGesture()
        setupToolBar()
        setupScrollView()
        setupNavigationBar()
        loadImage()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //Mark: - Convenience methods

    @objc
    func reachabilityChange(_ notification: Notification) {
        self.deleteButton.isEnabled = isNetworkReachable
    }

    func deletePhoto() {
        ImgurClient.apiCall(with: .delete(deletHash: photoRecord.deleteHash), onCompletion: { (response) in
            switch response {
            case .error(let error):
                if let error = error {
                    print(error.localizedDescription)
                    let alertController = UIAlertController(title: "Error", message: "Delete failed. \(error.localizedDescription)", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .cancel, handler: { (_) in
                        self.dismissOrPop(from: self, animated: true, completion: nil)
                    })
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            case .success(_):
                self.delegate?.didDeletePhoto(self, photo: self.photoRecord, at: self.indexPath)
            }
        })
    }

    func loadImage() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let networkEngine = NetworkEngineDataTask(taskType: .imageDownload(image: photoRecord))
        networkEngine.imageDownloadCompletionBlock = { [weak self] (image) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.imageToShow = image
            }
        }
        //networkEngine.progressBlock = { (progress) in
        //    //TODO: what to show? perhaps percent complete in the title?
        //}
        networkEngine.startDataTask()
    }

    func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(gesture:)))
        tapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(tapGesture)
    }

    func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.topAnchor.activeConstraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        scrollView.pinEdges([.left, .right], to: view)
        scrollView.bottomAnchor.activeConstraint(equalTo: toolBar.topAnchor)
        //scrollView.contentSize = imageView.bounds.size
        scrollView.addSubview(imageView)
    }

    func setupToolBar() {
        view.addSubview(toolBar)
        toolBar.heightAnchor.activeConstraint(equalToConstant: toolbarHeight)
        toolBar.pinEdges([.left, .right], to: view)
        toolBar.bottomAnchor.activeConstraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    }

    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = actionButton
    }

    @objc
    func handleDoubleTap(gesture: UITapGestureRecognizer) {
        if (scrollView.zoomScale > scrollView.minimumZoomScale) {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
        else {
            scrollView.setZoomScale(scrollView.maximumZoomScale, animated: true)
        }
    }

    @objc
    func tappedCloseButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @objc
    func showDeletePhotoAlert(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Warning", message: "Are you sure you want to delete this image from your Imgur account?  This action can not be undone.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (_) in
            self.deletePhoto()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        navigationController?.present(alertController, animated: true, completion: nil)
    }

    @objc
    func handleActionButton(sender: UIBarButtonItem) {
        if let image = self.imageToShow, let data = UIImageJPEGRepresentation(image, 0.75) {
            if let url = tempFileURL {
                OperationQueue.main.addOperation {
                    if let _ = try? data.write(to: url, options: [.atomicWrite]) {
                        self.documentinteractionController.url = url
                        self.documentinteractionController.name = url.lastPathComponent
                        self.documentinteractionController.presentOpenInMenu(from: self.actionButton, animated: true)
                    }
                }
            }
        }
    }
    
    func setZoomScale() {
        scrollView.contentSize = imageView.bounds.size

        let imageViewSize = imageView.bounds.size
        let scrollViewSize = scrollView.bounds.size
        let widthScale = scrollViewSize.width / imageViewSize.width
        let heightScale = scrollViewSize.height / imageViewSize.height
        
        scrollView.minimumZoomScale = min(widthScale, heightScale)
        scrollView.zoomScale = scrollView.minimumZoomScale
    }
    
    override func viewWillLayoutSubviews() {
        centerImageInScrollView()
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageInScrollView()
    }
    
    func centerImageInScrollView() {
        let iSize = imageView.frame.size
        let sSize = scrollView.bounds.size
        let vPadding = iSize.height < sSize.height ? (sSize.height - iSize.height) / 2 : 0
        let hPadding = iSize.width < sSize.width ? (sSize.width - iSize.width) / 2 : 0
        scrollView.contentInset = UIEdgeInsets(top: vPadding, left: hPadding, bottom: vPadding, right: hPadding)
    }
}

extension PhotoViewController: UIDocumentInteractionControllerDelegate {

    func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController) {
        if let url = URL(string: tempFilePath) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func documentInteractionController(_ controller: UIDocumentInteractionController, didEndSendingToApplication application: String?) {
        if let url = URL(string: tempFilePath) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

extension PhotoViewController: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
