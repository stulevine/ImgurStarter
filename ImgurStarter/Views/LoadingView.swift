//
//  LoadingView.swift
//  Netbility
//
//  Created by Stuart Levine on 2/5/17.
//  Copyright © 2017 Wildcatproductions. All rights reserved.
//

import UIKit

struct LoadingViewTheme {
    var labelColor: UIColor
}

class LoadingView: UIView {
    var theme = LoadingViewTheme(labelColor: UIColor.white.withAlphaComponent(0.75))
    var lastAngle: Double = 0.0
    var percentComplete: Double = 0.0 {
        didSet {
            self.centerLabel.text = "\((self.percentComplete*100.0).roundTo0f)%"
        }
    }
    lazy var centerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.textColor = self.theme.labelColor
        label.text = "0 %"
        return label
    }()

    init() {
        super.init(frame: .zero)

        commonInit()
    }

    init(theme: LoadingViewTheme? = nil) {
        super.init(frame: .zero)
        if let theme = theme {
            self.theme.labelColor = theme.labelColor
        }

        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    func commonInit() {
        addSubview(centerLabel)
        centerLabel.centerXAnchor.activeConstraint(equalTo: centerXAnchor)
        centerLabel.firstBaselineAnchor.activeConstraint(equalTo: centerYAnchor, constant: 5)

        self.alpha = 0.0
    }

    override func layoutSubviews() {

        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
        }
    }
}

extension Double {
    var roundTo0f: String {
        return NSString(format: "%.0f", self) as String
    }
}
