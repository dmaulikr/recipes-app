//
//  CurrentUser.swift
//  Recipes
//
//  Created by Tushar Verma on 1/17/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit

class CurrentUser: NSObject {
    static var userId:String = ""
    static var userName:String = ""
        
    static func clearCurrentUser() {
        self.userId = ""
        self.userName = ""
    }
}
