//
//  RecipesService.swift
//  Recipes
//
//  Created by Tushar Verma on 3/31/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit

class RecipesService: NSObject {
    
    let dataTaskUtil:DataTaskUtil = DataTaskUtil()

    func retrieveRecipes(cachedRecipes:[Int:Recipe], completionHandler: @escaping (Bool, [Recipe]) -> Swift.Void) {

        var json:[String:String] = [String:String]()
        json["fb_user_id"] = CurrentUser.userId
        
        let url = Config.ScriptUrl.retrieveRecipesURL
        var headers = [String:String]()
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"

        var recipes = [Recipe]()
        dataTaskUtil.executeHttpRequest(url: url, httpMethod: .post, headerFieldValuePairs: headers, jsonPayload: json as NSDictionary) { (data, response, error) in
            
            if !self.dataTaskUtil.isValidResponse(response: response, error: error) {
                completionHandler(false, [])
                return
            }
            
            let dataDictionary:NSDictionary? = self.dataTaskUtil.getJson(data: data!)
            if !self.dataTaskUtil.isValidJson(json: dataDictionary) {
                completionHandler(false, [])
                return
            }
            
            let dataArray = dataDictionary?["recipes"] as! NSArray
            for i in 0 ..< dataArray.count {
                let recipeDictionary = dataArray[i] as! NSDictionary
                
                // Skip if this recipe has already been loaded
                let recipeId:Int = recipeDictionary["recipe_id"] as! Int
                if cachedRecipes[recipeId] != nil {
                    print("already loaded recipe with id \(recipeId), skipping")
                    recipes.append(cachedRecipes[recipeId]!)
                    continue
                }
                
                let recipe:Recipe = Recipe()
                recipe.recipeId = recipeId
                recipe.name = recipeDictionary["name"] as! String
                recipe.recipeDescription =  recipeDictionary["description"] as! String
                recipe.imageUrl = recipeDictionary["image_url"] as! String
                
                // Parse and save each ingredient
                let ingredientsArray = recipeDictionary["ingredients"] as! NSArray
                for j in 0 ..< ingredientsArray.count {
                    let ingredientsDictionary = ingredientsArray[j] as! NSDictionary
                    
                    let ingredient:String = ingredientsDictionary["ingredient"] as! String
                    let ingredient_id:Int = ingredientsDictionary["ingredient_id"] as! Int
                    
                    recipe.ingredients.append(ingredient)
                    recipe.ingredientToIdMap[ingredient] = ingredient_id
                }
                
                // Parse and save each instruction
                let instructionsArray = recipeDictionary["instructions"] as! NSArray
                for j in 0 ..< instructionsArray.count {
                    let instructionsDictionary = instructionsArray[j] as! NSDictionary
                    
                    let instruction:String = instructionsDictionary["instruction"] as! String
                    let instruction_id:Int = instructionsDictionary["instruction_id"] as! Int
                    
                    recipe.instructions.append(instruction)
                    recipe.instructionToIdMap[instruction] = instruction_id
                }
                
                recipes.append(recipe)
                
            }
            
            completionHandler(true, recipes)
        }
    }
    
    func loadRecipeImages(recipes:[Recipe], cachedRecipes:[Int:Recipe], completionHandler: @escaping ([Recipe]) -> Swift.Void) {
        
        // Create queue for running the download tasks in parallel
        let queue = DispatchQueue(label: "test", qos: .userInitiated, attributes: .concurrent)
        
        // Implements semaphore to figure out when all tasks in queue are done
        let group = DispatchGroup()
        
        let domainName:String = Config.ScriptUrl.domainName
        
        for i in 0 ..< recipes.count {
            let recipe:Recipe = recipes[i]
            
            // If there is no image url, just continue
            if recipe.imageUrl == "" {
                continue
            }
            
            // Skip if the recipe has already been loaded
            if cachedRecipes[recipe.recipeId] != nil {
                print("already loaded image for recipe with id \(recipe.recipeId), skipping")
                continue
            }
            
            // Increase semaphore
            group.enter()
            
            // Add a download task for each recipe image
            queue.async(group: group, execute: {
                
                // Create request to download image
                let url:URL? = URL(string: domainName + recipe.imageUrl)
                let myPicture = UIImage(data: try! Data(contentsOf: url!))!
                                
                recipes[i].image = myPicture
                print("loaded image")
                
                // Decrease semaphore
                group.leave()
            })
        }

        group.notify(queue: DispatchQueue.main) {
            completionHandler(recipes)
        }
    }
    
}
