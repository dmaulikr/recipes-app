//
//  NSMutableDataExtensions.swift
//  Recipes
//
//  Created by Tushar Verma on 4/2/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit

extension NSMutableData {
    func appendString(string: String) {
        let data:Data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)!
        append(data)
    }
}
