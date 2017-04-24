//
//  UIViewControllerExtensions.swift
//  Recipes
//
//  Created by Tushar Verma on 4/2/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let gestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        
        // Don't disable other tap gestures in the view
        gestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(gestureRecognizer)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}
