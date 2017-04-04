//
//  UITextViewExtensions.swift
//  Recipes
//
//  Created by Tushar Verma on 4/3/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit

extension UITextView {
    func getSizeThatFits() -> CGSize {
        let fixedWidth:CGFloat = self.frame.size.width
        let newSize:CGSize = self.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        return newSize
    }
}
