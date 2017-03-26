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
    
    func saveRecipesToFile(recipesToSave:[Recipe], filePath:String, minifyImages:Bool) -> Bool {
        if minifyImages {
            for i in 0 ..< recipesToSave.count {
                if let image = recipesToSave[i].image {
                    let reducedImage = image.resized(withPercentage: Config.defaultImageResizeScale)
                    recipesToSave[i].image = reducedImage
                }
            }
        }
        
        let data = NSKeyedArchiver.archivedData(withRootObject: recipesToSave)
        do {
            try data.write(to: URL(fileURLWithPath: filePath))
        } catch {
            print("Couldn't write to recipes file")
            return false
        }
        
        print("Successfully saved \(recipesToSave.count) recipes to \(filePath)")
        return true
    }

}
