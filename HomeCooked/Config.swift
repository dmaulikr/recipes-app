//
//  Config.swift
//  Recipes
//
//  Created by Tushar Verma on 3/25/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit

class Config: NSObject {
    
    static let sharedInstance = Config()
    private var configs: NSDictionary!
    
    enum ConfigProperty:String {
        case loggingLevel = "loggingLevel"
        case domainName = "domainName"
        case apiBaseUrl = "apiBaseUrl"
    }
    
    enum APIEndpoint:String {
        case saveRecipe = "saveRecipe"
        case saveRecipeImage = "saveRecipeImage"
        case saveFBAccount = "saveFBAccount"
        case retrieveRecipes = "retrieveRecipes"
        case updateRecipe = "updateRecipe"
        case deleteRecipe = "deleteRecipe"
    }
    
    struct Color {
        static let darkBlueColor:UIColor = UIColor(displayP3Red: 3/255, green: 27/255, blue: 51/255, alpha: 1)
        static let darkBlueColorHex:Int = 0x031B33
    
        static let lightGreyLineColor:UIColor = UIColor(displayP3Red: 136/255, green: 148/255, blue: 149/255, alpha: 0.25)
        static let lightGreyLineColorHext:Int = 0x9AABAF
    
        static let greyBorderColor:UIColor = UIColor(displayP3Red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
    }
    
    struct Image {
        static let defaultImageResizeScale:CGFloat = 0.1
    }
    
    struct UserDefaultsKey {
        static let mainDirectoryFilePathKey:String = "dataDirectory"
        static let recipesFilePathKey:String = "recipesFile"
        static let currentUserIdKey = "currentUserId"
        static let currentUserNameKey = "currentUserName"
    }
    
    override init() {
        let path = Bundle.main.path(forResource: "Config", ofType: "plist")!
        let currentConfiguration = Bundle.main.object(forInfoDictionaryKey: "Config")!
        self.configs = NSDictionary(contentsOfFile: path)!.object(forKey: currentConfiguration) as! NSDictionary
    }
    
    func getConfigProperty(property: ConfigProperty) -> String {
        return self.configs.object(forKey: property.rawValue) as! String
    }
    
    func getAPIEndpoint(endpoint: APIEndpoint) -> String {
        let apiBaseUrl = self.configs.object(forKey: ConfigProperty.apiBaseUrl.rawValue) as! String
        return apiBaseUrl + (self.configs.object(forKey: endpoint.rawValue) as! String)
    }
    
}
