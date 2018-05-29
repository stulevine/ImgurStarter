//
//  ViewController.swift
//  ImgurStarter
//
//  Created by Stuart Levine on 5/25/18.
//  Copyright © 2018 Wildcat Productions. All rights reserved.
//

import UIKit
import SafariServices
import CoreImage
import MobileCoreServices
import Photos
import Reachability

let jpegQuality: CGFloat = 0.75
let reachability = Reachability()
let kReachabilityChangedName = Notification.Name("kReachabilityChangedName")
var isNetworkReachable = true
var firstTimeLaunch = true

////
// Initial view controller
//
// Displays a collection of Imgur user photos when logged in
//
// - Provides the ability for a user to login/logout
// - Provides the ability for a user to upload a photo from their photo library (images only)
//
class ImgurViewController: UIViewController, UINavigationControllerDelegate {

    let maxImageSizeBytes: Double = 10485760.0
    let toolbarHeight:CGFloat = 50
    var safariViewController: SFSafariViewController?
    var totalImageCount = 0
    var images = [ImgurImage]()
    var collectionViewController: CollectionViewController?
    lazy var uploadButton: UIBarButtonItem = {
        let uploadButton = UIBarButtonItem(title: "Upload", style: .plain, target: self, action: #selector(showImagePicker(_:)))
        return uploadButton
    }()
    lazy var toolBar: UIToolbar = {
        let toolBar = UIToolbar()
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.isTranslucent = true
        let leftFlexibaleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let rightSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        rightSpacer.width = 20
        toolBar.setItems([leftFlexibaleSpace, uploadButton, rightSpacer], animated: true)

        return toolBar
    }()
    lazy var loginMessageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.textColor = .lightGray
        label.text = "Please login to Imgur."
        return label
    }()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    func commonInit() {
        reachability?.whenReachable = { [weak self] reachability in
            isNetworkReachable = true
            if !firstTimeLaunch {
                NotificationCenter.default.post(name: kReachabilityChangedName, object: isNetworkReachable)
                SlideupAlertView.show(message: "Good news! Internet connectivity is now available.", theme: .normal)
                self?.uploadButton.isEnabled = true
                self?.collectionViewController?.collectionView?.isScrollEnabled = true
                self?.collectionViewController?.loadDataSource()
            }
            firstTimeLaunch = false
        }
        reachability?.whenUnreachable = { [weak self] reachability in
            isNetworkReachable = false
            NotificationCenter.default.post(name: kReachabilityChangedName, object: isNetworkReachable)
            SlideupAlertView.show(message: "Connectivity is unavailable at this time.  Please try again when you are connected to the internet.", theme: .caution)
            self?.uploadButton.isEnabled = false
            self?.collectionViewController?.collectionView?.isScrollEnabled = false
            firstTimeLaunch = false
        }

        try? reachability?.startNotifier()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ImgurClient.user.loadFromKeychain()

        NotificationCenter.default.addObserver(self, selector: #selector(didRecieveAuthorizationResponse(_:)), name: kAuthorizationResponeReceivedNotificationName, object: nil)

        setupNavigationBar()
        setupToolBar()
        setupCollectionViewController()
        showEmptyStateIfNeeded()
    }

    func showEmptyStateIfNeeded() {
        if !ImgurClient.user.isAuthenticated {
            view.addSubview(loginMessageLabel)
            loginMessageLabel.topAnchor.activeConstraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            loginMessageLabel.bottomAnchor.activeConstraint(equalTo: toolBar.topAnchor)
            loginMessageLabel.pinEdges([.left, .right], to: view)
            uploadButton.isEnabled = false
        }
    }

    func hideEmptyState() {
        loginMessageLabel.removeFromSuperview()
        uploadButton.isEnabled = true
    }

    func setupToolBar() {
        view.addSubview(toolBar)
        toolBar.heightAnchor.activeConstraint(equalToConstant: toolbarHeight)
        toolBar.pinEdges([.left, .right], to: view)
        toolBar.bottomAnchor.activeConstraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    }

    func setupCollectionViewController() {
        let layout = UICollectionViewFlowLayout()
        let screenWidth = self.view.frame.width
        let itemsPerRow: CGFloat = 3

        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        let itemSize = round((screenWidth - (itemsPerRow+1) * layout.minimumInteritemSpacing) / itemsPerRow)
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        let collectionViewController = CollectionViewController(collectionViewLayout: layout)
        self.collectionViewController = collectionViewController
        if let collectionView = collectionViewController.collectionView {
            if traitCollection.forceTouchCapability != .unavailable {
                registerForPreviewing(with: collectionViewController, sourceView: collectionView)
            }

            collectionView.contentInset = UIEdgeInsets(top: layout.minimumInteritemSpacing, left: layout.minimumInteritemSpacing, bottom: toolbarHeight + layout.minimumInteritemSpacing, right: layout.minimumInteritemSpacing)
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(collectionView)
            collectionView.pinEdges([.top, .left, .right], to: self.view)
            collectionView.bottomAnchor.activeConstraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            addChildViewController(collectionViewController)
            collectionViewController.didMove(toParentViewController: self)
        }
    }

    func setupNavigationBar() {
        title = "Imgur Starter"
        if ImgurClient.user.isAuthenticated {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout(_:)))
        }
        else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Login", style: .plain, target: self, action: #selector(login(_:)))
        }
    }

    @objc
    func logout(_ sender: UIBarButtonItem) {
        ImgurClient.user.logout()

        setupNavigationBar()
        showEmptyStateIfNeeded()
        collectionViewController?.dataSource.removeAll()
        collectionViewController?.collectionView?.reloadData()
    }

    @objc
    func login(_ sender: UIBarButtonItem) {
        showAuthorization()
    }

    func showAuthorization() {
        if let safariViewController = ImgurClient.authorizationController() {
            safariViewController.delegate = self
            self.safariViewController = safariViewController
            self.navigationController?.present(safariViewController, animated: true, completion: nil)
        }
    }

    @objc
    func didRecieveAuthorizationResponse(_ notification: NSNotification) {
        self.safariViewController?.dismiss(animated: true, completion: nil)

        guard let userInfo = notification.userInfo as? [String: Any], let responseUrl = userInfo[kAuthorizationUrlKey] as? URL else { return }

        ImgurClient.user.importValuesFrom(url: responseUrl)
        setupNavigationBar()
        hideEmptyState()
        collectionViewController?.loadDataSource()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc
    func showImagePicker(_ sender: UIBarButtonItem) {
        let controller = UIImagePickerController()
        controller.sourceType = UIImagePickerControllerSourceType.photoLibrary
        controller.mediaTypes = [String(kUTTypeImage)]
        controller.delegate = self
        navigationController?.present(controller, animated: true, completion: nil)
    }
}

////
// When a user has finished selecting a photo from their Photo Library, we will initial an upload
// and present the Upload view controller
//
extension ImgurViewController: UIImagePickerControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage, let jpgImage = UIImageJPEGRepresentation(image, jpegQuality) {
            let imageSize = Double(jpgImage.count)
            if imageSize > maxImageSizeBytes {
                let alertController = UIAlertController(title: "Error. Upload Failed.", message: "The file size exceeds the Imgur file size limit of 10MB.  Please choose another photo to upload.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(okAction)
                picker.dismiss(animated: true) {
                    self.navigationController?.present(alertController, animated: true, completion: nil)
                }

                return
            }
        }

        picker.dismiss(animated: true) {
            let uploadViewController = UploadViewController(imageInfo: info, completion: { [weak self] (photo) in
                self?.collectionViewController?.addToDataSource(photo)
            })
            uploadViewController.modalPresentationStyle = .overCurrentContext
            self.navigationController?.present(uploadViewController, animated: true, completion: nil)
        }

    }
}

////
// dimisses the SFSafariViewController after receiving the OAuth2 callback
//
extension ImgurViewController: SFSafariViewControllerDelegate {

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
