//
//  FileManagerService.swift
//  Recipes
//
//  Created by Tushar Verma on 3/25/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit

class FileManagerService: NSObject {
    
    private var fileManager = FileManager.default
    private var documentsHomeDirectory:URL!
    
    override init() {
        let dirPaths = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        self.documentsHomeDirectory = dirPaths[0]
    }
    
    func getFileManager() -> FileManager {
        return self.fileManager
    }
    
    func getDocumentsDirectory() -> URL {        
        return self.documentsHomeDirectory
    }
    
    func createDirectory(path: String, withIntermediateDirectories: Bool, attributes: [String : Any]?) -> Bool {
        
        do {
            try fileManager.createDirectory(atPath: path,
                                            withIntermediateDirectories: withIntermediateDirectories,
                                            attributes: attributes)
        }
        catch let error as NSError {
            print("Error creating directory: \(error.localizedDescription)")
            return false
        }
        
        print("Successfully created \(path)")
        return true
    }
    
    func removeItem(path: String) -> Bool {
        do {
            try fileManager.removeItem(atPath: path)
        }
        catch let error as NSError {
            print("Error deleting item: \(error.localizedDescription)")
            return false
        }
        
        print("Successfully deleted \(path)")
        return true

    }
    
    func saveRecipesToFile(recipesToSave:[Recipe], filePath:String, minifyImages:Bool, appendToFile:Bool) -> Bool {
        if minifyImages {
            for i in 0 ..< recipesToSave.count {
                if let image = recipesToSave[i].image {
                    let reducedImage = image.resized(withPercentage: Config.defaultImageResizeScale)
                    recipesToSave[i].image = reducedImage
                }
            }
        }
        
        var allRecipesToSave:[Recipe] = recipesToSave
        if appendToFile {
            if let savedRecipes = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [Recipe] {
                allRecipesToSave = savedRecipes + recipesToSave
            }
        }
        
        let data = NSKeyedArchiver.archivedData(withRootObject: allRecipesToSave)
        do {
            try data.write(to: URL(fileURLWithPath: filePath))
        } catch let error as NSError {
            print("Couldn't write to recipes file: \(error.localizedDescription)")
            return false
        }
        
        print("Successfully saved \(recipesToSave.count) recipes to \(filePath)")
        return true
    }
    
    func overwriteRecipe(withRecipeId:Int, newRecipe:Recipe, filePath:String, minifyImage:Bool) -> Bool {
        guard var savedRecipes = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [Recipe] else {
            print("recipe doesn't exist")
            return false
        }
        
        var recipeExists:Bool = false
        for i in 0 ..< savedRecipes.count {
            if savedRecipes[i].recipeId == withRecipeId {
                recipeExists = true
                savedRecipes[i] = newRecipe
                if minifyImage {
                    if let image = savedRecipes[i].image {
                        let reducedImage = image.resized(withPercentage: Config.defaultImageResizeScale)
                        savedRecipes[i].image = reducedImage
                    }
                }
                break
            }
        }
        
        if !recipeExists {
            print("recipe doesn't exist")
            return false
        }
        
        let data = NSKeyedArchiver.archivedData(withRootObject: savedRecipes)
        do {
            try data.write(to: URL(fileURLWithPath: filePath))
        } catch let error as NSError {
            print("Couldn't write to recipes file: \(error.localizedDescription)")
            return false
        }
        
        print("Recipe overwritten successfully")
        return true
    }

}
