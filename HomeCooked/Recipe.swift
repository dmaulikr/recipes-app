//
//  Recipe.swift
//  Recipes
//
//  Created by Tushar Verma on 11/10/16.
//  Copyright © 2016 Tushar Verma. All rights reserved.
//

import UIKit

class Recipe: NSObject, NSCoding {
    var recipeId:Int = -1
    var name:String = ""
    var recipeDescription:String = ""
    var ingredients:[String] = [String]()
    var instructions:[String] = [String]()
    var ingredientToIdMap:[String:Int] = [String:Int]()
    var instructionToIdMap:[String:Int] = [String:Int]()
    var image:UIImage?
    var imageUrl:String = ""
    
    // A constructor is required for the NSCoding protocol
    override init() {
        
    }
    
    
    // MARK: - NSCoding protocol methods
    
    required convenience init?(coder decoder: NSCoder) {
        self.init()
        self.recipeId = decoder.decodeInteger(forKey: "recipeId")
        self.name = decoder.decodeObject(forKey: "name") as! String
        self.recipeDescription = decoder.decodeObject(forKey: "recipeDescription") as! String
        self.ingredients = decoder.decodeObject(forKey: "ingredients") as! [String]
        self.instructions = decoder.decodeObject(forKey: "instructions") as! [String]
        self.ingredientToIdMap = decoder.decodeObject(forKey: "ingredientToIdMap") as! [String : Int]
        self.instructionToIdMap = decoder.decodeObject(forKey: "instructionToIdMap") as! [String : Int]
        self.image = decoder.decodeObject(forKey: "image") as! UIImage?
        self.imageUrl = decoder.decodeObject(forKey: "imageUrl") as! String
    }
    
    func encode(with encoder: NSCoder) {
        encoder.encode(recipeId, forKey: "recipeId")
        encoder.encode(name, forKey: "name")
        encoder.encode(recipeDescription, forKey: "recipeDescription")
        encoder.encode(ingredients, forKey: "ingredients")
        encoder.encode(instructions, forKey: "instructions")
        encoder.encode(ingredientToIdMap, forKey: "ingredientToIdMap")
        encoder.encode(instructionToIdMap, forKey: "instructionToIdMap")
        encoder.encode(image, forKey: "image")
        encoder.encode(imageUrl, forKey: "imageUrl")
    }
    
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
