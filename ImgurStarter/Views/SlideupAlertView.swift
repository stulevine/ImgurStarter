//
//  SlideoutAlertView.swift
//  ImgurStarter
//
//  Created by Stuart Levine on 5/28/18.
//  Copyright © 2018 Wildcat Productions. All rights reserved.
//

import Foundation
import UIKit

enum AlertStatusTheme: UInt {
    case caution = 0xFF2020
    case normal = 0x217d07

    var color: UIColor {
        return UIColor.withHex(self.rawValue)
    }
    var icon: UIImage? {
        switch self {
        case .caution:
            return UIImage(named: "caution")?.withRenderingMode(.alwaysTemplate)
        case .normal:
            return UIImage(named: "greencirclecheckmark")
        }
    }
    var tintColor: UIColor? {
        switch self {
        case .caution: return self.color
        default: return nil
        }
    }
}

class SlideupAlertView: UIView {

    private static var alertView: SlideupAlertView = SlideupAlertView()
    private static var isAlertViewShowing: Bool = false

    lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss(_:)))
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = 1
        return gesture
    }()
    var cautionIcon: UIImageView = {
        let view = UIImageView(image: UIImage(named: "caution")?.withRenderingMode(.alwaysTemplate))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tintColor = .white
        view.heightAnchor.activeConstraint(equalToConstant: 30)
        view.widthAnchor.activeConstraint(equalToConstant: 30)
        view.contentMode = .scaleAspectFit
        return view
    }()
    var messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .light)
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    init() {
        let screenSize = UIApplication.shared.keyWindow?.frame.size ?? UIScreen.main.bounds.size
        let rect = CGRect(origin: CGPoint(x: 0, y: screenSize.height+50), size: CGSize(width: screenSize.width, height: 110))

        super.init(frame: rect)

        addGestureRecognizer(tapGesture)
        addSubview(cautionIcon)
        addSubview(messageLabel)
        cautionIcon.topAnchor.activeConstraint(equalTo: topAnchor, constant: 25)
        cautionIcon.leftAnchor.activeConstraint(equalTo: leftAnchor, constant: 20)
        messageLabel.rightAnchor.activeConstraint(equalTo: rightAnchor, constant: -20)
        messageLabel.leftAnchor.activeConstraint(equalTo: cautionIcon.rightAnchor, constant: 20)
        messageLabel.centerYAnchor.activeConstraint(equalTo: cautionIcon.centerYAnchor)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func show(message: String, animated: Bool = true, theme: AlertStatusTheme) {
        _ = Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: { (timer) in
            self.hide(timer)
        })

        alertView.backgroundColor = .white
        alertView.cautionIcon.tintColor = theme.tintColor ?? alertView.cautionIcon.tintColor
        alertView.cautionIcon.image = theme.icon
        alertView.messageLabel.text = message
        let screenSize = UIApplication.shared.keyWindow?.frame.size ?? UIScreen.main.bounds.size
        alertView.alpha = 0
        // Reset to below the bottom of the screen before presenting
        var origin = alertView.frame.origin
        origin.y = screenSize.height + 50
        alertView.frame.origin = origin
        UIApplication.shared.keyWindow?.addSubview(alertView)
        origin.y = screenSize.height - alertView.frame.height

        UIView.animateKeyframes(withDuration: 0.5,
                                delay: 0,
                                options: UIView.KeyframeAnimationOptions.calculationModeCubic,
                                animations: {

            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.25, animations: {
                alertView.alpha = 1.0
            })
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5, animations: {
                alertView.frame.origin = origin
            })
        })
    }

    static func hide(_ timer: Timer? = nil, animated: Bool = true) {
        guard !isAlertViewShowing else { return }
        timer?.invalidate()
        let screenSize = UIApplication.shared.keyWindow?.frame.size ?? UIScreen.main.bounds.size
        // Reset to below the bottom of the screen before presenting
        var origin = alertView.frame.origin
        origin.y = screenSize.height + alertView.frame.height

        UIView.animateKeyframes(withDuration: 0.5,
                                delay: 0,
                                options: UIView.KeyframeAnimationOptions.calculationModeCubic,
                                animations: {

            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.3, animations: {
                alertView.alpha = 0
            })
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations: {
                alertView.frame.origin = origin
            })
        }) { (done) in
            alertView.removeFromSuperview()
        }
    }

    @objc
    func tapToDismiss(_ sender: UITapGestureRecognizer) {
       SlideupAlertView.hide()
    }
}
