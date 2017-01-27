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
    var ingredientToIdMap:[String:Int] = [String:Int]()
    var instructionToIdMap:[String:Int] = [String:Int]()
    var image:UIImage?
    var imageUrl:String = ""
    
    func toString() -> String {
        var str = "name: " + self.name + "\n"
        str += String(format: "recipe id: %d", recipeId) + "\n"
        str += "description: " + recipeDescription + "\n"
        str += "ingredients: " + ingredients.description + "\n"
        str += "instructions: " + instructions.description + "\n"
        str += "ingredientsToIdMap: " + ingredientToIdMap.description + "\n"
        str += "instructionsToIdMap: " + instructionToIdMap.description + "\n"
        str += "imageUrl: " + imageUrl + "\n"
        
        return str
    }
}
