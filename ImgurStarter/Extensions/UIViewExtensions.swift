//
//  UIViewExtensions.swift
//
//  Created by Stuart Levine on 4/27/18.
//  Copyright © 2018 Wildcat Productions. All rights reserved.
//

import Foundation
import UIKit

/**
 *  A convenience method to pin a view's edges to another provided view using anchors
 *
 *  @param  edges: UIRectEdge - determines which edges to ping
 *  @param  view: UIView -to view to apply constrain anchors to
 *  @param  topInset: CGFloat - topAnchor constant (optional)
 *  @param  leftInset: CGFloat - leftAnchor constant (optional)
 *  @param  bottomInset: CGFloat - bottomAnchor constant (optional)
 *  @param  rightInset: CGFloat - righAnchor constant (optional)
 */
extension UIView {

    func pinEdges(_ edges: UIRectEdge, to view: UIView, topInset: CGFloat = 0.0, leftInset: CGFloat = 0.0, bottomInset: CGFloat = 0.0, rightInset: CGFloat = 0.0) {
        if edges.contains(.left) {
            self.leftAnchor.constraint(equalTo: view.leftAnchor, constant: leftInset).isActive = true
        }
        if edges.contains(.right) {
            self.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -rightInset).isActive = true
        }
        if edges.contains(.top) {
            self.topAnchor.constraint(equalTo: view.topAnchor, constant: topInset).isActive = true
        }
        if edges.contains(.bottom) {
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomInset).isActive = true
        }
    }
}
