//
//  FileManagerService.swift
//  Recipes
//
//  Created by Tushar Verma on 3/25/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit

class RecipesFileManagerUtil: FileManager {
    
    private var documentsHomeDirectory:URL!
    
    override init() {
        super.init()
        let dirPaths = super.urls(for: .documentDirectory, in: .userDomainMask)
        self.documentsHomeDirectory = dirPaths[0]
    }
    
    func getDefaultFileManager() -> FileManager {
        return FileManager.default
    }
    
    func getDocumentsDirectory() -> URL {
        return self.documentsHomeDirectory
    }
    
    @discardableResult
    func createDirectory(path: String, withIntermediateDirectories: Bool, attributes: [String : Any]?) -> Bool {
        
        do {
            try super.createDirectory(atPath: path,
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
    
    @discardableResult
    func removeItem(path: String) -> Bool {
        do {
            try super.removeItem(atPath: path)
        }
        catch let error as NSError {
            print("Error deleting item: \(error.localizedDescription)")
            return false
        }
        
        print("Successfully deleted \(path)")
        return true
        
    }
    
    @discardableResult
    func saveRecipesToFile(recipesToSave:[Recipe], filePath:String, appendToFile:Bool) -> Bool {
        
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
    
    @discardableResult
    func overwriteRecipe(withRecipeId:Int, newRecipe:Recipe, filePath:String) -> Bool {
        guard var savedRecipes = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [Recipe] else {
            print("recipe doesn't exist")
            return false
        }
        
        var recipeExists:Bool = false
        for i in 0 ..< savedRecipes.count {
            if savedRecipes[i].recipeId == withRecipeId {
                recipeExists = true
                savedRecipes[i] = newRecipe                
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
        
        print("Recipe successfully overwritten")
        return true
    }
    
}
