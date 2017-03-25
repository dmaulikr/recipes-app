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
    
    var recipes:[Recipe] = [Recipe]()
    var recipesToDisplay:[Recipe] = [Recipe]()
    var selectedRecipe:Recipe?
    var addImageClicked:Bool = false
    var currentLeftBarButtonItem:UIBarButtonSystemItem = UIBarButtonSystemItem.edit
    var refreshControl:UIRefreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.startActivityIndicators()
        
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

                let recipe:Recipe = Recipe()
                recipe.recipeId = recipeDictionary["recipe_id"] as! Int
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
        
        let session:URLSession = URLSession.shared
        let domainName:String = "http://iosrecipes.com/"
        
        for i in 0..<self.recipes.count {
            let recipe:Recipe = self.recipes[i]
            
            // If there is no image url, just continue
            if recipe.imageUrl == "" {
                continue
            }
            
            // Increase semaphore
            group.enter()
            
            // Add a download task for each recipe image
            queue.async(group: group, execute: {
                
                // Create request to download image
                let url:URL? = URL(string: domainName + recipe.imageUrl)
                let myPicture = UIImage(data: try! Data(contentsOf: url!))!                
                self.recipes[i].image = myPicture.resized(withPercentage: 1 / Config.defaultImageResizeScale)
                print("loaded image")
                    
                // Decrease semaphore
                group.leave()
            
            
            })
        }
        
        group.notify(queue: DispatchQueue.main) {
            print("done loading images, displaying recipes")
            
            // Handle either initial load(activity indicator) or user refresh (refresh control)
            self.endActivityIndicators()
            self.refreshControl.endRefreshing()
            
            // Adjust the table view and display data
            self.tableViewHeightConstraint.constant = CGFloat(self.recipes.count) * self.defaultTableRowHeight
            self.recipesToDisplay = self.recipes
            self.recipesTableView.reloadData()
            
            // Display labels and icons appropriately
            self.displayLabels()
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

