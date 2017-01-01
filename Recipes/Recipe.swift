//
//  Recipe.swift
//  Recipes
//
//  Created by Tushar Verma on 11/10/16.
//  Copyright © 2016 Tushar Verma. All rights reserved.
//

import UIKit

class Recipe: NSObject {
    var recipeId:Int = -1
    var name:String = ""
    var recipeDescription:String = ""
    var ingredients:[String] = [String]()
    var instructions:[String] = [String]()
    var image:UIImage?
    var ingredientToIdMap:[String:Int] = [String:Int]()
    var instructiontToIdMap:[String:Int] = [String:Int]()
    
    func toString() -> String {
        var str = self.name + "\n"
        str += recipeDescription + "\n"
        str += ingredients.description + "\n"
        str += instructions.description + "\n"
        str += ingredientToIdMap.description + "\n"
        str += instructiontToIdMap.description + "\n"
        str += String(format: "recipe id: %d", recipeId) + "\n"
        str += "image: "
        if image != nil {
            str += "true"
        }
        else {
            str += "false"
        }
        
        return str
    }
}
