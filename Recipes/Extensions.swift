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
