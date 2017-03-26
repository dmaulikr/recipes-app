//
//  Extensions.swift
//  Recipes
//
//  Created by Tushar Verma on 1/5/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let gestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        
        // Don't let gesture recognizer selctor be triggered when a view, such as a button
        // or table cell is touched
        gestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(gestureRecognizer)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension NSMutableData {
    func appendString(string: String) {
        let data:Data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)!
        append(data)
    }
}

extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }
        
    var png: Data? { return UIImagePNGRepresentation(self) }
    
    func jpeg(_ quality: JPEGQuality) -> Data? {
        return UIImageJPEGRepresentation(self, quality.rawValue)
    }
    
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        
        // print("original size: " + String(describing: self.size))
        
        let newSize = self.size.applying(CGAffineTransform(scaleX: percentage, y: percentage))
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        UIGraphicsBeginImageContextWithOptions(newSize, !hasAlpha, scale)
        
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // print("new size: " + String(describing: resizedImage?.size))
        return resizedImage
    }
    
    
    func resized(toWidth width: CGFloat) -> UIImage? {
        
        // print("original size: " + String(describing: self.size))
        
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))

        UIGraphicsBeginImageContextWithOptions(canvasSize, false, 0)
        draw(in: CGRect(origin: .zero, size: canvasSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // print("new size: " + String(describing: resizedImage?.size))
        return resizedImage
    }
    
    func resized(toWidth:CGFloat, toHeight:CGFloat) -> UIImage? {
        var actualHeight = self.size.height
        var actualWidth = self.size.width
        var imgRatio = actualWidth/actualHeight
        let maxRatio = toWidth / toHeight
        
        // print("original size: " + String(describing: self.size))
        
        if imgRatio != maxRatio {
            if imgRatio < maxRatio {
                imgRatio = toHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = toHeight
            }
            else{
                imgRatio = toWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = toWidth
            }
        }
        
        let rect = CGRect(x: 0, y: 0, width: actualWidth, height: actualHeight)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        
        draw(in: rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // print("new size: " + String(describing: resizedImage?.size))
        return resizedImage
    }
 
}
