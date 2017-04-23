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
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var noRecipesLabel: UILabel!
    @IBOutlet weak var getStartedLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var recipesTableView: UITableView!
    
    @IBOutlet weak var searchBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    // Constants
    let defaultTableRowHeight:CGFloat = 100
    let placeholderViewAlpha:CGFloat = 0.25
    
    // Misc
    let alertControllerUtil = AlertControllerUtil()
    let fileManagerUtil = RecipesFileManagerUtil()
    let recipesService = RecipesService()
    
    lazy var maxTableHeight:CGFloat = {
        return UIScreen.main.bounds.height
            - self.topLayoutGuide.length
            - self.searchBarHeightConstraint.constant
            - self.bottomLayoutGuide.length
            - 10 // extra buffer
    }()
    var savedRecipesMap:[Int:Recipe] = [Int:Recipe]()
    var recipes:[Recipe] = [Recipe]()
    var recipesToDisplay:[Recipe] = [Recipe]()
    var selectedRecipe:Recipe?
    var addImageClicked:Bool = false
    var currentLeftBarButtonItem:UIBarButtonSystemItem = UIBarButtonSystemItem.edit
    var refreshControl:UIRefreshControl = UIRefreshControl()
    var placeholderView:UIView?
    
    // This variable indicates whether this class will make a remote call to load the recipes for a user
    // If set to false, the data cached in the file system will be used
    // Can be set by anyone presenting this view controller
    var loadRecipes:Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let recipesFile = UserDefaults.standard.object(forKey: Config.UserDefaultsKey.recipesFilePathKey) as! String
        if let savedRecipes = NSKeyedUnarchiver.unarchiveObject(withFile: recipesFile) as? [Recipe] {
            for i in 0 ..< savedRecipes.count {
                let recipeId = savedRecipes[i].recipeId
                self.savedRecipesMap[recipeId] = savedRecipes[i]
                self.recipes.append(savedRecipes[i])
            }
        }
        print("loaded " + String(self.savedRecipesMap.count) + " recipes from file system")
        self.recipes = self.recipes.sorted(by: { $0.name <= $1.name })
        
        // Pull to refresh
        refreshControl.addTarget(self, action: #selector(ViewController.handleRefresh), for: UIControlEvents.valueChanged)
        self.recipesTableView.addSubview(refreshControl)
        self.recipesTableView.backgroundColor = UIColor.clear
        
        // Set up delegates
        self.searchBar.delegate = self
        self.recipesTableView.delegate = self
        self.recipesTableView.dataSource = self
        
        // Dismiss keyboard when user taps outside
        self.hideKeyboardWhenTappedAround()
        
        // Retreive recipes and populate view
        // If we don't need to load them, then display them after the subviews have been added
        self.tableViewHeightConstraint.constant = 0
        if self.loadRecipes {
            self.retrieveRecipes(startIndicators: true)
        }
    }
    
    override func viewDidLayoutSubviews() {
        // If there's no need to load the recipes, just display them
        if !self.loadRecipes {
            // Need to know the top and bottom layout guides in order to display recipes
            // Don't display if recipes have already been displayed
            if self.recipesToDisplay.count == 0 && self.topLayoutGuide.length != 0 && self.bottomLayoutGuide.length != 0 {
                self.startActivityIndicators()
                self.displayRecipes(recipes: self.recipes)
                self.endActivityIndicators()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleRefresh() {
        // Hard refresh, so clear caches
        self.recipes = []
        self.savedRecipesMap.removeAll()
        self.retrieveRecipes(startIndicators: false)
    }
    
    func retrieveRecipes(startIndicators:Bool) {
        
        print("loading recipes from server")
        if startIndicators {
            self.startActivityIndicators()
        }                
        
        recipesService.retrieveRecipes(cachedRecipes: self.savedRecipesMap) { (success, recipes) in
            if !success {
                print("There was an error retrieving the recipes")
                DispatchQueue.main.async {
                    self.endActivityIndicators()
                    self.alertControllerUtil.displayErrorAlert(presentOn: self, actionToRetry: {
                        self.retrieveRecipes(startIndicators: startIndicators)
                    })
                }
                return
            }
            
            self.recipes = recipes
            DispatchQueue.main.async {
                self.loadRecipeImages(startIndicators: false)
            }
        }
    }
    
    func loadRecipeImages(startIndicators:Bool) {
        
        if startIndicators {
            self.startActivityIndicators()
        }
        
        self.recipesService.retrieveRecipeImages(recipes: self.recipes, cachedRecipes: self.savedRecipesMap) { (recipes) in
            print("done loading images, displaying recipes")
            
            // If any new recipes have been retrieved, update the recipes file and local cache
            if self.recipes.count > self.savedRecipesMap.count {
                print("new recipes found, updating file system and local cache")
                let recipesFile = UserDefaults.standard.object(forKey: Config.UserDefaultsKey.recipesFilePathKey) as! String
                self.fileManagerUtil.saveRecipesToFile(recipesToSave: self.recipes, filePath: recipesFile, appendToFile: false)
                
                for i in 0 ..< self.recipes.count {
                    self.savedRecipesMap[self.recipes[i].recipeId] = self.recipes[i]
                }
            }
            
            // Handle either initial load(activity indicator) or user refresh (refresh control)
            self.endActivityIndicators()
            self.refreshControl.endRefreshing()
            self.displayRecipes(recipes: self.recipes)
        }        
    }
    
    func deleteRecipes(recipeIds:[Int]) {
        
        if recipeIds.count == 0 {
            print("No recipes to delete")
            return
        }
        
        print("deleting recipes")
        recipesService.deleteRecipes(recipeIds: recipeIds) { (success) in
            if !success {
                print("There was an error deleting the recipe")
                DispatchQueue.main.async {
                    self.alertControllerUtil.displayErrorAlert(presentOn: self, actionToRetry: {
                        self.deleteRecipes(recipeIds: recipeIds)
                    })
                }
                return
            }
            print("Successfully removed recipes")
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
            
    // MARK: - Utility functions
    
    func displayRecipes(recipes:[Recipe]) {
        self.adjustTableViewHeight()
        self.recipesToDisplay = recipes
        self.recipesTableView.reloadData()
        self.displayLabels()
    }
    
    func adjustTableViewHeight() {
        self.tableViewHeightConstraint.constant = CGFloat(self.recipes.count) * self.defaultTableRowHeight
        if self.tableViewHeightConstraint.constant > self.maxTableHeight {
            self.tableViewHeightConstraint.constant = self.maxTableHeight
        }
    }
    
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
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if searchBar.text == nil || searchBar.text == "" {
            // Create placeholder view to display with empty search bar
            // Allows users to click on the screen and dismiss the keyboard without clicking on a recipe
            if self.placeholderView == nil {
                let yCoord = searchBar.frame.origin.y + searchBar.frame.height
                let screenSize = UIScreen.main.bounds
                
                let frame = CGRect(x: 0, y: yCoord, width: screenSize.width, height: screenSize.height)
                self.placeholderView = UIView(frame: frame)
                
                self.placeholderView!.backgroundColor = UIColor.black
                self.placeholderView!.alpha = self.placeholderViewAlpha
                self.view.addSubview(self.placeholderView!)
            }
            else {
                self.placeholderView!.alpha = self.placeholderViewAlpha
            }
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.placeholderView?.alpha = 0
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText == "" {
            self.placeholderView?.alpha = self.placeholderViewAlpha
            self.recipesToDisplay = self.recipes
            self.recipesTableView.reloadData()
            return
        }
        self.placeholderView?.alpha = 0
        
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
    

    // MARK: - Table View Delegate Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recipesToDisplay.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableCell")!
        
        let recipe:Recipe = self.recipesToDisplay[indexPath.row]
        
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
            
            let index = self.recipes.index(of: recipeToDelete)
            self.recipes.remove(at: index!)

            self.displayRecipes(recipes: self.recipes)
            DispatchQueue.global(qos: .background).async {
                let recipesFile = UserDefaults.standard.object(forKey: Config.UserDefaultsKey.recipesFilePathKey) as! String
                self.savedRecipesMap.removeValue(forKey: recipeToDelete.recipeId)
                self.fileManagerUtil.saveRecipesToFile(recipesToSave: self.recipes, filePath: recipesFile, appendToFile: false)                                            
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor.clear
    }
    
}

