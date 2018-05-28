//
//  UIImageExtensions.swift
//  SlidingPuzzle
//
//  Created by Stuart Levine on 5/3/18.
//  Copyright © 2018 Stuart Levine. All rights reserved.
//

import Foundation
import UIKit
import CoreImage

extension UIImage {

    func scaleImage(to size: Int) -> UIImage? {
        var scaledImage: UIImage? = nil
        var height: CGFloat = self.size.height
        var width: CGFloat = self.size.width
        if width > height {
            width = CGFloat(size) / height * width
            height = CGFloat(size)
        }
        else {
            height = CGFloat(size) / width * height
            width = CGFloat(size)
        }

        let scaledRect = CGRect(x: 0, y: 0, width: width, height: height)
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        self.draw(in: scaledRect)
        scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }

    class func xImage(width: CGFloat, color: UIColor, weight: CGFloat = 2.0) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: width), false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.saveGState()
        context.setStrokeColor(color.cgColor)
        context.setLineCap(CGLineCap.round)
        context.setLineWidth(weight)
        let adjustedX: CGFloat = 0.0+weight
        let adjustedY: CGFloat = width-weight
        context.move(to: CGPoint(x: adjustedX, y: adjustedX))
        context.addLine(to: CGPoint(x: adjustedY, y: adjustedY))
        context.move(to: CGPoint(x: adjustedX, y: adjustedY))
        context.addLine(to: CGPoint(x: adjustedY, y: adjustedX))
        context.strokePath()
        context.restoreGState()

        let image = UIGraphicsGetImageFromCurrentImageContext()

        return image
    }

    public convenience init?(color: UIColor) {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

