//
//  Config.swift
//  Recipes
//
//  Created by Tushar Verma on 3/25/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit

class Config: NSObject {
    
    static let darkBlueColor:UIColor = UIColor(displayP3Red: 3/255, green: 27/255, blue: 51/255, alpha: 1)
    static let darkBlueColorHex:Int = 0x031B33
    
    static let lightGreyLineColor:UIColor = UIColor(displayP3Red: 136/255, green: 148/255, blue: 149/255, alpha: 0.25)
    static let lightGreyLineColorHext:Int = 0x9AABAF
    
    static let greyBorderColor:UIColor = UIColor(displayP3Red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
    
    static let defaultImageResizeScale:CGFloat = 0.1
    
    static let mainDirectoryFilePathKey:String = "dataDirectory"
    static let recipesFilePathKey:String = "recipesFile"
    
    
}
