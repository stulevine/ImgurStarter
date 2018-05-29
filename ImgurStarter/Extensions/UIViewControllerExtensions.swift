//
//  UIViewControllerExtensions.swift
//  ImgurStarter
//
//  Created by Stuart Levine on 5/28/18.
//  Copyright © 2018 Wildcat Productions. All rights reserved.
//

import Foundation
import UIKit
import Reachability

typealias NetworkStatusHandler = (Bool)->()

extension UIViewController {

    func dismissOrPop(from viewController: UIViewController, animated: Bool, completion: (()->())?) {
        if let topViewController = viewController.navigationController?.topViewController, topViewController == self {
            self.navigationController?.popViewController(animated: animated)
        }
        else {
            self.dismiss(animated: animated, completion: completion)
        }
    }
}
