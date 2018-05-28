//
//  NSLayoutExtensions.swift
//
//  Created by Stuart Levine on 5/10/18.
//  Copyright © 2018 Stuart Levine. All rights reserved.
//

import Foundation
import UIKit

extension NSLayoutDimension {

    @discardableResult func activeConstraint(equalTo anchor: NSLayoutAnchor<NSLayoutDimension>) -> NSLayoutConstraint {
        let item = constraint(equalTo: anchor)
        item.isActive = true
        return item
    }

    @discardableResult func activeConstraint(equalTo anchor: NSLayoutAnchor<NSLayoutDimension>, constant c: CGFloat) -> NSLayoutConstraint {
        let item = constraint(equalTo: anchor, constant: c)
        item.isActive = true
        return item
    }

    @discardableResult func activeConstraint(equalToConstant c: CGFloat) -> NSLayoutConstraint {
        let item = constraint(equalToConstant: c)
        item.isActive = true
        return item
    }

    @discardableResult func activeConstraint(equalTo anchor: NSLayoutDimension, multiplier m: CGFloat) -> NSLayoutConstraint {
        let item = constraint(equalTo: anchor, multiplier: m)
        item.isActive = true
        return item
    }
}

extension NSLayoutXAxisAnchor {

    @discardableResult func activeConstraint(equalTo anchor: NSLayoutAnchor<NSLayoutXAxisAnchor>) -> NSLayoutConstraint {
        let item = constraint(equalTo: anchor)
        item.isActive = true
        return item
    }

    @discardableResult func activeConstraint(equalTo anchor: NSLayoutAnchor<NSLayoutXAxisAnchor>, constant c: CGFloat) -> NSLayoutConstraint {
        let item = constraint(equalTo: anchor, constant: c)
        item.isActive = true
        return item
    }
}

extension NSLayoutYAxisAnchor {

    @discardableResult func activeConstraint(equalTo anchor: NSLayoutAnchor<NSLayoutYAxisAnchor>) -> NSLayoutConstraint {
        let item = constraint(equalTo: anchor)
        item.isActive = true
        return item
    }

    @discardableResult func activeConstraint(equalTo anchor: NSLayoutAnchor<NSLayoutYAxisAnchor>, constant c: CGFloat) -> NSLayoutConstraint {
        let item = constraint(equalTo: anchor, constant: c)
        item.isActive = true
        return item
    }
}
