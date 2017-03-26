//
//  ViewController.swift
//  Recipes
//
//  Created by Tushar Verma on 11/10/16.
//  Copyright © 2016 Tushar Verma. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    // UI outlets
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var noRecipesLabel: UILabel!
    @IBOutlet weak var getStartedLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var recipesTableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    // Constants
    let retrieveRecipesURL:String = "http://iosrecipes.com/retrieveRecipes.php"
    let deleteRecipesUrl:String = "http://iosrecipes.com/deleteRecipeData.php"
    let defaultTableRowHeight:CGFloat = 100

    // Misc
    let alertService = AlertControllerService()
    let dataTaskService = DataTaskService()
    let fileManagerService = FileManagerService()
    
    var savedRecipesMap:[Int:Recipe] = [Int:Recipe]()
    var recipes:[Recipe] = [Recipe]()
    var recipesToDisplay:[Recipe] = [Recipe]()
    var selectedRecipe:Recipe?
    var addImageClicked:Bool = false
    var currentLeftBarButtonItem:UIBarButtonSystemItem = UIBarButtonSystemItem.edit
    var refreshControl:UIRefreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create file on device for saving recipes
        let filemgr = self.fileManagerService.getFileManager()
        let directoryHome = self.fileManagerService.getDocumentsDirectory().path
        let dataDir = directoryHome + "/date"
        let recipesFile = dataDir + "/recipes"
        
        if !filemgr.fileExists(atPath: dataDir) {
            print("creating data directory")
            fileManagerService.createDirectory(path: dataDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        if !filemgr.fileExists(atPath: recipesFile) {
            print("creating recipes file")
            filemgr.createFile(atPath: recipesFile, contents: nil, attributes: nil)
        }
        
        // Cache the file system data
        UserDefaults.standard.set(dataDir, forKey: "dataDirectory")
        UserDefaults.standard.set(recipesFile, forKey: "recipesFile")

        /*
        if let savedRecipes = NSKeyedUnarchiver.unarchiveObject(withFile: recipesFile) as? [Recipe] {
            for i in 0 ..< savedRecipes.count {
                let recipeId = savedRecipes[i].recipeId
                
                // Resize image
                if let image = savedRecipes[i].image {
                    let screenWidth:CGFloat = UIScreen.main.bounds.width
                    savedRecipes[i].image = image.resized(toWidth: screenWidth, toHeight: screenWidth * 0.67)
                }
                
                // Can't cache savedRecipesMap to UserDefaults because it doesn't except general Object types
                self.savedRecipesMap[recipeId] = savedRecipes[i]
            }
        }*/
        print("loaded " + String(self.savedRecipesMap.count) + " recipes from file system")
        
        // Pull to refresh
        refreshControl.addTarget(self, action: #selector(ViewController.handleRefresh), for: UIControlEvents.valueChanged)
        self.recipesTableView.addSubview(refreshControl)
        self.recipesTableView.backgroundColor = UIColor.clear
        
        // Set up search controller
        self.searchBar.delegate = self
        
        // Set up delegats
        self.searchBar.delegate = self
        self.recipesTableView.delegate = self
        self.recipesTableView.dataSource = self
        
        // Dismiss keyboard when user taps outside
        self.hideKeyboardWhenTappedAround()
        
        // Retreive recipes and populate view
        self.tableViewHeightConstraint.constant = 0
        self.retrieveRecipes()
        
    }
    
    func handleRefresh() {
        self.retrieveRecipes()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func retrieveRecipes() {
        
        self.startActivityIndicators()
        
        // Create json object
        var json:[String:String] = [String:String]()
        json["fb_user_id"] = CurrentUser.userId
        
        let data:Data = try! JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        // Create url object
        let url:URL = URL(string: self.retrieveRecipesURL)!
        
        // Create and initialize request
        var request:URLRequest = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.httpBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Create task to retrieve recipes from url
        let task:URLSessionDataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in            
            
            if !self.dataTaskService.isValidResponse(response: response, error: error) {
                print("There was an error retrieving the recipes")
                DispatchQueue.main.async {
                    self.endActivityIndicators()
                    self.alertService.displayErrorAlert(presentOn: self, actionToRetry: {
                        self.retrieveRecipes()
                    })
                }
                return
            }
            
            let dataDictionary:NSDictionary? = self.dataTaskService.getJson(data: data!)
            if !self.dataTaskService.isValidJson(json: dataDictionary) {
                print("There was an error retrieving the recipes")
                print(dataDictionary ?? "json: {}")
                DispatchQueue.main.async {
                    self.endActivityIndicators()
                    self.alertService.displayErrorAlert(presentOn: self, actionToRetry: {
                        self.retrieveRecipes()
                    })
                }
                return
            }
                
            // Get array of json recipe objects
            let dataArray = dataDictionary?["recipes"] as! NSArray
            
            // Loop through array and parse each recipe
            // Clear array since it's possible to have recipes in it during user refresh
            self.recipes = []
            for i in 0 ..< dataArray.count {
                let recipeDictionary = dataArray[i] as! NSDictionary
                
                // Skip if this recipe has already been loaded
                let recipeId:Int = recipeDictionary["recipe_id"] as! Int
                if self.savedRecipesMap[recipeId] != nil {
                    print("already loaded recipe with id \(recipeId), skipping")
                    let savedRecipe = self.savedRecipesMap[recipeId]
                    self.recipes.append(savedRecipe!)
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
                    
                // Add to recipes array
                self.recipes.append(recipe)
                    
            }
            
            // Update the recipe image in the main thread
            DispatchQueue.main.async {
                self.loadRecipeImages()
            }
        }
        
        // Run the task
        task.resume()
        
    }
    
    func loadRecipeImages() {
        
        // Create queue for running the download tasks in parallel
        let queue = DispatchQueue(label: "test", qos: .userInitiated, attributes: .concurrent)
        
        // Implements semaphore to figure out when all tasks in queue are done
        let group = DispatchGroup()
        
        let domainName:String = "http://iosrecipes.com/"
        
        for i in 0..<self.recipes.count {
            let recipe:Recipe = self.recipes[i]
            
            // If there is no image url, just continue
            if recipe.imageUrl == "" {
                continue
            }
            
            // Skip if the recipe has already been loaded
            if self.savedRecipesMap[recipe.recipeId] != nil {
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
                
                let screenWidth:CGFloat = UIScreen.main.bounds.width
                self.recipes[i].image = myPicture.resized(toWidth: screenWidth, toHeight: screenWidth * 0.67)
                print("loaded image")
                    
                // Decrease semaphore
                group.leave()
            
            
            })
        }
        
        group.notify(queue: DispatchQueue.main) {
            print("done loading images, displaying recipes")
            
            // Update the recipes ios file
            let recipesFile = UserDefaults.standard.object(forKey: "recipesFile") as! String
            self.fileManagerService.saveRecipesToFile(recipesToSave: self.recipes, filePath: recipesFile, minifyImages: true)
            
            // Update savedRecipesMap
            for i in 0 ..< self.recipes.count {
                self.savedRecipesMap[self.recipes[i].recipeId] = self.recipes[i]
            }
            
            // Handle either initial load(activity indicator) or user refresh (refresh control)
            self.endActivityIndicators()
            self.refreshControl.endRefreshing()
            self.displayRecipes()
        }
    }
    
    
    @IBAction func leftBarButtonClicked(_ sender: UIBarButtonItem) {

        var setBarButtonItem:UIBarButtonSystemItem!
        var isEditing:Bool!
        
        if self.currentLeftBarButtonItem == UIBarButtonSystemItem.edit {
            // If user presses on Edit button, change button to Done
            isEditing = true
            setBarButtonItem = UIBarButtonSystemItem.done
        }
        else {
            // If user presses Done, change button to Edit and delete the recipes
            isEditing = false
            setBarButtonItem = UIBarButtonSystemItem.edit
        }
        
        // Set editing
        self.recipesTableView.setEditing(isEditing, animated: true)
        
        // Set left bar button
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: setBarButtonItem,
            target: self,
            action: #selector(self.leftBarButtonClicked(_:))
        )
        
        // Update current bar button and clear recipes to delete array
        self.currentLeftBarButtonItem = setBarButtonItem

    }

    @IBAction func addRecipeButtonClicked(_ sender: UIBarButtonItem) {
        // Specify we are not coming from an add image click for prepare(for segue) func
        self.addImageClicked = false
        self.performSegue(withIdentifier: "createRecipe", sender: self)
    }
    
    @IBAction func addImageClicked(buttonWithRecipe:ButtonWithRecipe) {
        // Need to set data used by prepare(for segue) func
        self.selectedRecipe = buttonWithRecipe.associatedRecipe
        self.addImageClicked = true
        self.performSegue(withIdentifier: "createRecipe", sender: self)
    }
    
    func deleteRecipes(recipeIds:[Int]) {
        
        if recipeIds.count == 0 {
            print("No recipes to delete")
            return
        }
        
        print("deleting recipes")
        
        // Create json object
        var json:[String:[Int]] = [String:[Int]]()
        json["recipe_ids"] = recipeIds
                
        let data:Data = try! JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        // Create url object
        let url:URL = URL(string: self.deleteRecipesUrl)!
        
        // Create and initialize request
        var request:URLRequest = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.httpBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task:URLSessionDataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if !self.dataTaskService.isValidResponse(response: response, error: error) {
                print("There was an error deleting the recipe")
                DispatchQueue.main.async {
                    self.alertService.displayErrorAlert(presentOn: self, actionToRetry: {
                        self.deleteRecipes(recipeIds: recipeIds)
                    })
                }
                return
            }

            let json:NSDictionary? = self.dataTaskService.getJson(data: data!)
            if !self.dataTaskService.isValidJson(json: json) {
                print("There was an error deleting the recipe")
                print(json ?? "json: {}")
                DispatchQueue.main.async {
                    self.alertService.displayErrorAlert(presentOn: self, actionToRetry: {
                        self.deleteRecipes(recipeIds: recipeIds)
                    })
                }
                return
            }

            print("Successfully removed recipes")
            
        }
        
        task.resume()
    }
    
    
    
    // MARK: - Utility functions
    
    func displayLabels() {
        if self.recipes.count > 0 {
            self.noRecipesLabel.alpha = 0
            self.getStartedLabel.alpha = 0
        }
        else {
            self.noRecipesLabel.alpha = 1
            self.getStartedLabel.alpha = 1
        }
    }
    
    func startActivityIndicators() {
        self.activityIndicator.startAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func endActivityIndicators() {
        self.activityIndicator.stopAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false    
    }
    
    func displayRecipes() {
        // Adjust the table view and display data
        self.tableViewHeightConstraint.constant = CGFloat(self.recipes.count) * self.defaultTableRowHeight
        self.recipesToDisplay = self.recipes
        self.recipesTableView.reloadData()
        
        // Display labels and icons appropriately
        self.displayLabels()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Initialize recipe object for RecipeViewController
        if segue.identifier == "toRecipeView" {
            let recipeVC:RecipeViewController = segue.destination as! RecipeViewController
            recipeVC.recipe = self.selectedRecipe
        }
        else if self.addImageClicked && segue.identifier == "createRecipe" {
            // Only want to pass in a recipe to edit if the user clicked the add image button
            let createRecipeVC = segue.destination as! CreateRecipeViewController
            createRecipeVC.recipeToEdit = self.selectedRecipe
            createRecipeVC.editingRecipe = true
        }
    }
    
    // MARK: - Search Bar Delegate methods
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText == "" {
            self.recipesToDisplay = self.recipes
            self.recipesTableView.reloadData()
            return
        }
        
        let searchTextLowerCase:String = searchText.lowercased()
        
        self.recipesToDisplay = self.recipes.filter({ (recipe:Recipe) -> Bool in
            
            let match = recipe.name.lowercased().range(of: searchTextLowerCase)
            if match != nil {
                return true
            }
            else {
                return false
            }
            
        })
        
        self.recipesTableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {       
        self.recipesToDisplay = self.recipes
        self.recipesTableView.reloadData()
    }

    // MARK: - Table View Delegate Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recipesToDisplay.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get reusable cell
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableCell")!
        
        // Get recipe
        let recipe:Recipe = self.recipesToDisplay[indexPath.row]
        
        // Initialize label text with recipe name
        let label:UILabel = cell.viewWithTag(1) as! UILabel
        label.text = recipe.name
        
        // Since we're using a reusable cell, we need to clear any previous image that it had
        let imageView:UIImageView = cell.viewWithTag(2) as! UIImageView
        imageView.image = nil
        
        let addImageButton:ButtonWithRecipe = cell.viewWithTag(3) as! ButtonWithRecipe
        addImageButton.alpha = 0
        
        if let image = self.recipesToDisplay[indexPath.row].image {
            imageView.image = image
        }
        else {
            addImageButton.alpha = 1
            addImageButton.associatedRecipe = self.recipesToDisplay[indexPath.row]
            addImageButton.addTarget(self, action: #selector(self.addImageClicked(buttonWithRecipe:)), for: UIControlEvents.touchUpInside)
        }
                
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Need to set selected recipe for prepare(for segue) function
        self.selectedRecipe = self.recipesToDisplay[indexPath.row]
        self.performSegue(withIdentifier: "toRecipeView", sender: self)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.defaultTableRowHeight
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            let recipeToDelete = self.recipesToDisplay[indexPath.row]
            
            self.deleteRecipes(recipeIds: [recipeToDelete.recipeId])
            
            // remove from recipes array
            let index = self.recipes.index(of: recipeToDelete)
            self.recipes.remove(at: index!)
            self.recipesToDisplay = self.recipes

            // Adjust table height and display data
            self.tableViewHeightConstraint.constant -= self.defaultTableRowHeight
            self.recipesTableView.reloadData()
            
            // Show appropriate labels
            displayLabels()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor.clear
    }
    
}

