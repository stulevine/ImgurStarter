//
//  UploadViewController.swift
//  ImgurStarter
//
//  Created by Stuart Levine on 5/26/18.
//  Copyright © 2018 Wildcat Productions. All rights reserved.
//
import Foundation
import UIKit

typealias UploadCompletionBlock = (ImgurImage?)->()

////
//  Provides an UI interface to allow a user to select a photo from thier photo libray
//  and upload it to their Imgur account
//
class UploadViewController: UIViewController {

    let startUploadString = "Start upload"
    let doneString = "Done"
    let cancelString = "Cancel"
    let photoString = "Photo to upload"
    let progressString = "Upload progress"

    var completion: UploadCompletionBlock?
    var image: UIImage?
    var imageTitle: String?
    var imageInfo: [String: Any]
    var thumbnail: UIImage?
    var photo: ImgurImage?
    var dataTask: NetworkEngineDataTask?

    var progress: Float = 0 {
        didSet {
            self.progressView.progress = self.progress
            self.progressLabel.text = "\((Double(self.progress) * 100.0).roundTo0f) %"
        }
    }
    lazy var blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.alpha = 0.95
        blurView.translatesAutoresizingMaskIntoConstraints = false
        return blurView
    }()
    lazy var checkMarkImageView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "greencirclecheckmark"))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.heightAnchor.activeConstraint(equalToConstant: 40)
        view.widthAnchor.activeConstraint(equalToConstant: 40)
        return view
    }()
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 5
        view.clipsToBounds = true
        view.heightAnchor.activeConstraint(equalToConstant: 55)
        view.widthAnchor.activeConstraint(equalToConstant: 55)
        return view
    }()
    lazy var titleField: UITextField = {
        let field = UITextField()
        field.borderStyle = .line
        field.translatesAutoresizingMaskIntoConstraints = false
        field.returnKeyType = .done
        field.delegate = self
        field.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        field.textColor = .darkGray
        field.attributedPlaceholder = NSAttributedString(string: "Please enter a title",
                                                         attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        return field
    }()
    lazy var imageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.numberOfLines = 1
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        label.text = self.photoString
        label.heightAnchor.activeConstraint(equalToConstant: 15)
        return label
    }()
    lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.alpha = 0.0
        return label
    }()
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.numberOfLines = 1
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        label.text = self.progressString
        label.heightAnchor.activeConstraint(equalToConstant: 15)
        return label
    }()
    lazy var progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: UIProgressView.Style.bar)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.activeConstraint(equalToConstant: 12)
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.borderWidth = 1
        view.tintColor = .lightGray
        view.progressTintColor = .blue
        view.progress = 0.0

        return view
    }()
    var progressLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.numberOfLines = 1
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        label.text = "0 %"
        label.heightAnchor.activeConstraint(equalToConstant: 20)
        return label
    }()
    lazy var loadingViewContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.backgroundColor = UIColor.white
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.borderWidth = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.activeConstraint(equalToConstant: 100)
        view.widthAnchor.activeConstraint(equalToConstant: 250)

        return view
    }()
    lazy var startButton: UploadButton = {
        let button = UploadButton()
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.uploadStyle = .start
        button.adjustsImageWhenDisabled = true
        button.heightAnchor.activeConstraint(equalToConstant: 44)
        button.widthAnchor.activeConstraint(equalToConstant: 150)
        button.addTarget(self, action: #selector(tappedStartOrDoneButton(_:)), for: .touchUpInside)
        return button
    }()
    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.imageView?.contentMode = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.activeConstraint(equalToConstant: 40)
        button.widthAnchor.activeConstraint(equalToConstant: 40)
        button.setImage(UIImage.xImage(width: 25, color: .white), for: .normal)
        button.addTarget(self, action: #selector(tappedCloseButton(_:)), for: .touchUpInside)
        return button
    }()

    init(imageInfo: [String: Any], completion: UploadCompletionBlock?) {
        self.imageInfo = imageInfo

        super.init(nibName: nil, bundle: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChange(_:)), name: kReachabilityChangedName, object: nil)

        self.completion = completion

        view.addSubview(blurEffectView)
        view.addSubview(loadingViewContainer)
        view.addSubview(startButton)
        view.addSubview(closeButton)

        loadingViewContainer.addSubview(titleLabel)
        loadingViewContainer.addSubview(progressView)
        loadingViewContainer.addSubview(progressLabel)
        loadingViewContainer.addSubview(imageView)
        loadingViewContainer.addSubview(imageLabel)
        loadingViewContainer.addSubview(checkMarkImageView)
        loadingViewContainer.addSubview(titleField)
        loadingViewContainer.addSubview(errorLabel)

        blurEffectView.pinEdges(.all, to: view)
        closeButton.topAnchor.activeConstraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        closeButton.rightAnchor.activeConstraint(equalTo: view.rightAnchor, constant: -10)

        checkMarkImageView.centerXAnchor.activeConstraint(equalTo: loadingViewContainer.centerXAnchor)
        checkMarkImageView.centerYAnchor.activeConstraint(equalTo: loadingViewContainer.centerYAnchor, constant: 10)

        imageView.centerYAnchor.activeConstraint(equalTo: loadingViewContainer.centerYAnchor)
        imageView.leftAnchor.activeConstraint(equalTo: loadingViewContainer.leftAnchor, constant: 20)

        imageLabel.leftAnchor.activeConstraint(equalTo: imageView.rightAnchor, constant: 20)
        imageLabel.centerYAnchor.activeConstraint(equalTo: imageView.centerYAnchor, constant: -15)

        titleField.leftAnchor.activeConstraint(equalTo: imageLabel.leftAnchor)
        titleField.centerYAnchor.activeConstraint(equalTo: loadingViewContainer.centerYAnchor, constant: 15)

        loadingViewContainer.centerXAnchor.activeConstraint(equalTo: view.centerXAnchor)
        loadingViewContainer.centerYAnchor.activeConstraint(equalTo: view.centerYAnchor, constant: -50)

        titleLabel.topAnchor.activeConstraint(equalTo: loadingViewContainer.topAnchor, constant: 15)
        titleLabel.pinEdges([.left, .right], to: loadingViewContainer)

        progressView.topAnchor.activeConstraint(equalTo: titleLabel.bottomAnchor, constant: 10)
        progressView.pinEdges([.left, .right], to: loadingViewContainer, topInset: 0, leftInset: 15, bottomInset: 0, rightInset: 15)

        progressLabel.centerXAnchor.activeConstraint(equalTo: progressView.centerXAnchor, constant: 14)
        progressLabel.topAnchor.activeConstraint(equalTo: progressView.bottomAnchor, constant: 10)

        startButton.centerXAnchor.activeConstraint(equalTo: view.centerXAnchor)
        startButton.topAnchor.activeConstraint(equalTo: loadingViewContainer.bottomAnchor, constant: 50)

        errorLabel.pinEdges(.all, to: loadingViewContainer, topInset: 15, leftInset: 15, bottomInset: 15, rightInset: 15)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapToDismissKeyboard(_:)))
        view.addGestureRecognizer(tapGesture)

        image = imageInfo[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage

        thumbnail = image?.scaleImage(to: 100)
        imageView.image = thumbnail

        progressView.alpha = 0.0
        progressLabel.alpha = 0.0
        titleLabel.alpha = 0.0
        checkMarkImageView.alpha = 0.0
        startButton.isEnabled = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        view.setNeedsLayout()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }

    @objc
    func reachabilityChange(_ notification: Notification) {
        self.startButton.isEnabled = isNetworkReachable && (titleField.text?.count ?? 0) > 0
    }

    ////
    // Mehod invoked when a user taps the "Start Upload" button
    // Initials the API upload endpoint with the image data
    //
    func startUpload() {
        UIView.animateKeyframes(withDuration: 0.75, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.25) {
                self.imageView.alpha = 0.0
                self.imageLabel.alpha = 0.0
                self.titleField.alpha = 0.0
                self.closeButton.alpha = 0.0
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.25) {
                self.progressView.alpha = 1.0
                self.progressLabel.alpha = 1.0
                self.titleLabel.alpha = 1.0
            }
        }, completion: nil)

        if let image = image {
            let photoUpload = PhotoUpload(photo: image, title: titleField.text)

            dataTask = ImgurClient.apiCall(with: .upload(photo: photoUpload), onCompletion: { (response) in
                switch response {
                case .error(let error):
                    if let error = error as NSError? {
                        print(error.localizedDescription)
                        DispatchQueue.main.async(execute: { [weak self] in
                            self?.cleanup(message: "Upload Failed: \(error.localizedDescription)", error: error)
                        })
                   }
                case .success(let data):
                    DispatchQueue.main.async(execute: { [weak self] in
                        self?.cleanup(message: "Upload Complete", with: data)
                    })
                }
            }) { (percentComplete) in
                DispatchQueue.main.async { [weak self] in
                    self?.progress = Float(percentComplete)
                }
            }
        }
    }

    ////
    // A utility method to prepare for upload completion success and failure
    //
    func cleanup(message: String, with data: Any? = nil, error: NSError? = nil) {
        self.progress = 1.0
        UIView.animateKeyframes(withDuration: 0.25, delay: 0.0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.1, animations: {
                self.progressView.alpha = 0.0
                self.progressLabel.alpha = 0.0
            })
            UIView.addKeyframe(withRelativeStartTime: 0.05, relativeDuration: 0.1, animations: {
                self.startButton.uploadStyle = .done
                if error == nil {
                    self.checkMarkImageView.alpha = 1.0
                    self.titleLabel.text = message
                }
                else {
                    self.titleLabel.alpha = 0.0
                    self.errorLabel.alpha = 1.0
                    self.errorLabel.text = message
                }
            })
        }, completion: { (done) in
            guard error == nil else { return }
            // get the response Image object so we can inject it via completion block
            // and add it to the collectionView dataSource
            if
                let photoDict = (data as? [String: Any])?["data"] as? [String: Any],
                let photoData = try? JSONSerialization.data(withJSONObject: photoDict, options: []),
                let photo = try? JSONDecoder().decode(ImgurImage.self, from: photoData) {
                self.photo = photo
            }
        })
    }

    @objc
    func tappedStartOrDoneButton(_ sender: UploadButton) {
        switch sender.uploadStyle {
        case .start:
            UIView.animate(withDuration: 0.25, animations: {
                sender.uploadStyle = .cancel
            }) { (done) in
                self.startUpload()
            }
        case .cancel:
            sender.uploadStyle = .done
            dataTask?.cancelDataTask()
            self.dismiss(animated: true, completion: nil)
        case .done:
            self.dismiss(animated: true, completion: {
                self.completion?(self.photo)
            })
        }
    }

    @objc
    func tappedCloseButton(_ sender: UIButton) {
        titleField.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }

    @objc
    func tapToDismissKeyboard(_ gesture: UITapGestureRecognizer) {
        titleField.resignFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension UploadViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        startButton.isEnabled = isNetworkReachable && (titleField.text?.count ?? 0) > 0
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

enum UploadButtonStyle: Int {
    case start
    case cancel
    case done
}

class UploadButton: UIButton {

    var uploadStyle: UploadButtonStyle = .start {
        didSet {
            self.applyStyle(uploadStyle)
        }
    }

    private func applyStyle(_ style: UploadButtonStyle) {
        let startUploadString = "Start upload"
        let doneString = "Done"
        let cancelString = "Cancel"

        self.setTitleColor(.white, for: .normal)
        self.setTitleColor(UIColor.white.withAlphaComponent(0.8), for: .disabled)

        switch style {
        case .start:
            self.setTitle(startUploadString, for: .normal)
            self.setBackgroundImage(UIImage(color: UIColor.withHex(0x70b3ff)), for: .disabled)
            self.setBackgroundImage(UIImage(color: UIColor.withHex(0x1583ff)), for: .normal)
        case .done:
            self.setTitle(doneString, for: .normal)
            self.setBackgroundImage(UIImage(color: UIColor.withHex(0x70b3ff)), for: .disabled)
            self.setBackgroundImage(UIImage(color: UIColor.withHex(0x1583ff)), for: .normal)
        case .cancel:
            self.setTitle(cancelString, for: .normal)
            self.setBackgroundImage(UIImage(color: UIColor.withHex(0xFF2020)), for: .disabled)
            self.setBackgroundImage(UIImage(color: UIColor.withHex(0xFF5050)), for: .normal)
        }
    }
}



// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
