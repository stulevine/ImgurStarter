//
//  UIColorExtensions.swift
//  SlidingPuzzle
//
//  Created by Stuart Levine on 5/14/18.
//  Copyright © 2018 Stuart Levine. All rights reserved.
//

import Foundation
import UIKit

public extension UIColor {
    static func withHex(_ value: UInt, alpha: Float = 1.0) -> UIColor {
        return UIColor(red: CGFloat((value & 0xFF0000) >> 16)/255.0,
                       green: CGFloat((value & 0x00FF00) >>  8)/255.0,
                       blue: CGFloat((value & 0x0000FF) >>  0)/255.0,
                       alpha: CGFloat(alpha))
    }
}
