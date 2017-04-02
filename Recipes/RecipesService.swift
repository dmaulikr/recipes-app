//
//  RecipesService.swift
//  Recipes
//
//  Created by Tushar Verma on 3/31/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit

class RecipesService: NSObject {
    
    private let dataTaskUtil:DataTaskUtil = DataTaskUtil()
    
    func createRecipe(recipe:Recipe, imageId: Int?, completionHandler: @escaping (Bool, NSDictionary) -> Swift.Void) {
        
        var json:[String:AnyObject] = [
            "fb_user_id" : CurrentUser.userId as AnyObject,
            "name" : recipe.name as AnyObject,
            "description" : recipe.recipeDescription as AnyObject,
            "ingredients" : recipe.ingredients as AnyObject,
            "instructions" : recipe.instructions as AnyObject
        ]
        
        json["image_id"] = "" as AnyObject
        if imageId != nil {
            json["image_id"] = imageId! as AnyObject
        }
        
        var url = Config.ScriptUrl.saveRecipeUrl
        var headers = [String:String]()
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        
        dataTaskUtil.executeHttpRequest(url: url, httpMethod: .post, headerFieldValuePairs: headers, jsonPayload: json as NSDictionary) { (data, response, error) in
            
            if !self.dataTaskUtil.isValidResponse(response: response, error: error) {
                completionHandler(false, NSDictionary())
                return
            }
            
            let json:NSDictionary? = self.dataTaskUtil.getJson(data: data!)
            if !self.dataTaskUtil.isValidJson(json: json) {
                completionHandler(false, NSDictionary())
                return
            }
            
            completionHandler(true, json!)
        }
    }
    
    func saveRecipeImage(image: UIImage, completionHandler: @escaping (Bool, NSDictionary) -> Swift.Void) {
        
        let imageData:Data = image.jpeg(UIImage.JPEGQuality.high)!
        
        let boundary:String = "Boundary-\(NSUUID().uuidString)"
        let filePathKey:String = "file"
        let filename:String = "tmp.jpg" // the script will create the actual file name
        let mimetype:String = "image/jpg"
        
        let body:NSMutableData = NSMutableData()
        body.appendString(string: "--\(boundary)\r\n")
        body.appendString(string: "Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n")
        body.appendString(string: "Content-Type: \(mimetype)\r\n\r\n")
        body.append(imageData)
        body.appendString(string: "\r\n")
        body.appendString(string: "--\(boundary)--\r\n")
        
        let url = Config.ScriptUrl.saveRecipeImageUrl
        var headers = [String:String]()
        headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        
        
        dataTaskUtil.executeHttpRequest(url: url, httpMethod: .post, headerFieldValuePairs: headers, httpBody: body as Data) {
            (data, response, error) in
            
            if !self.dataTaskUtil.isValidResponse(response: response, error: error) {
                completionHandler(false, NSDictionary())
                return
            }
            
            let json:NSDictionary? = self.dataTaskUtil.getJson(data: data!)
            if !self.dataTaskUtil.isValidJson(json: json) {
                completionHandler(false, NSDictionary())
                return
            }
            
            completionHandler(true, json!)
        }
    }
    

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
    
    func retrieveRecipeImages(recipes:[Recipe], cachedRecipes:[Int:Recipe], completionHandler: @escaping ([Recipe]) -> Swift.Void) {
        
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
    
    func updateRecipe(recipe:Recipe, imageId:Int?, deleteImage:Bool, ingredientsToDelete:[Int], instructionsToDelete:[Int], completionHandler: @escaping (Bool, NSDictionary) -> Swift.Void) {
        
        var json:[String:AnyObject] = [
            "fb_user_id" : CurrentUser.userId as AnyObject,
            "name" : recipe.name as AnyObject,
            "description" : recipe.recipeDescription as AnyObject,
            "ingredients" : recipe.ingredients as AnyObject,
            "instructions" : recipe.instructions as AnyObject
        ]
        
        json["recipe_id"] = recipe.recipeId as AnyObject
        json["ingredient_to_id_map"] = recipe.ingredientToIdMap as AnyObject
        json["instruction_to_id_map"] = recipe.instructionToIdMap as AnyObject
        json["ingredients_to_delete"] = ingredientsToDelete as AnyObject
        json["instructions_to_delete"] = instructionsToDelete as AnyObject
        
        json["new_image_id"] = "" as AnyObject
        if imageId != nil {
            json["new_image_id"] = imageId! as AnyObject
        }
        json["delete_image"] = deleteImage as AnyObject?
        
        
        var url = Config.ScriptUrl.saveRecipeUrl
        var headers = [String:String]()
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        
        dataTaskUtil.executeHttpRequest(url: url, httpMethod: .post, headerFieldValuePairs: headers, jsonPayload: json as NSDictionary) { (data, response, error) in
            
            if !self.dataTaskUtil.isValidResponse(response: response, error: error) {
                completionHandler(false, NSDictionary())
                return
            }
            
            let json:NSDictionary? = self.dataTaskUtil.getJson(data: data!)
            if !self.dataTaskUtil.isValidJson(json: json) {
                completionHandler(false, NSDictionary())
                return
            }
            
            completionHandler(true, json!)
        }
        
    }
    
    func deleteRecipes(recipeIds: [Int], completionHandler: @escaping (Bool) -> Swift.Void) {
        var json:[String:[Int]] = [String:[Int]]()
        json["recipe_ids"] = recipeIds
        
        let url = Config.ScriptUrl.deleteRecipesUrl
        var headers = [String:String]()
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        
        dataTaskUtil.executeHttpRequest(url: url, httpMethod: .post, headerFieldValuePairs: headers, jsonPayload: json as NSDictionary) { (data, response, error) in
            
            if !self.dataTaskUtil.isValidResponse(response: response, error: error) {
                completionHandler(false)
                return
            }
            
            let json:NSDictionary? = self.dataTaskUtil.getJson(data: data!)
            if !self.dataTaskUtil.isValidJson(json: json) {
                completionHandler(false)
                return
            }
            
            completionHandler(true)
        }
    }
    
}
