//
//  StringExtensions.swift
//  Recipes
//
//  Created by Tushar Verma on 4/8/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit

extension String {
    
    func calculateHeight(inWidth: CGFloat, withFontSize: CGFloat) -> CGFloat {
        
        let attributes:[String:Any] = [NSFontAttributeName : UIFont.systemFont(ofSize: withFontSize)]
        let attributedString : NSAttributedString = NSAttributedString(string: self, attributes: attributes)
        
        let smallestPossibleSize:CGSize = CGSize(width: inWidth, height: CGFloat.greatestFiniteMagnitude)
        let smallestPossibleFrame:CGRect = attributedString.boundingRect(with: smallestPossibleSize, options: .usesLineFragmentOrigin, context: nil)
        
        let requredSize:CGRect = smallestPossibleFrame
        return requredSize.height + 15 // extra buffer
    }

}
