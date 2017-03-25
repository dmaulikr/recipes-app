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
    
    func jpeg(_ quality: JPEGQuality) -> Data? {
        return UIImageJPEGRepresentation(self, quality.rawValue)
    }
}
