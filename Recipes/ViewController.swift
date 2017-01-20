//
//  ViewController.swift
//  Recipes
//
//  Created by Tushar Verma on 11/10/16.
//  Copyright © 2016 Tushar Verma. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // UI outlets
    @IBOutlet weak var recipesTableView: UITableView!
    
    // Constants
    let retrieveRecipesURL:String = "http://iosrecipes.com/retrieveRecipes.php"
    let deleteRecipesUrl:String = "http://iosrecipes.com/deleteRecipeData.php"

    // Misc
    var recipes:[Recipe] = [Recipe]()
    var selectedRecipe:Recipe?
    var currentLeftBarButtonItem:UIBarButtonSystemItem = UIBarButtonSystemItem.edit
    var recipeIdsToDelete:[Int] = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.recipesTableView.delegate = self
        self.recipesTableView.dataSource = self
        
        // Assign function handlers for nav bar buttons
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.edit, target: self, action: #selector(self.leftBarButtonClicked(_:)))
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(self.addButtonClicked(_:)))

        // Set nav bar colors
        self.navigationController?.navigationBar.barTintColor = DefaultColors.darkBlueColor
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        
        // Dismiss keyboard when user taps outside
        self.hideKeyboardWhenTappedAround()
        
        // Retreive recipes and populate view
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
            
            if error != nil {
                NSLog("There was an error loading the url, " + (error?.localizedDescription)!)
                return
            }
            
            var dataDictionary:[String:Any]?
            do {
                // Convert recipe data to json array
                dataDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:Any]
            }
            catch let e as NSError {
                NSLog("Error: couldn't parse json, " + e.localizedDescription)
                return
            }
                
            // Get array of json recipe objects
            let dataArray = dataDictionary?["recipes"] as! NSArray
                
            // Loop through array and parse each recipe
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
                    recipe.instructiontToIdMap[instruction] = instruction_id
                }
                    
                print(recipe.toString())
                // Add to recipes array
                self.recipes.append(recipe)
                    
            }
                
            DispatchQueue.main.async {
                // Reload table view in main thread
                self.getRecipeImages()
                self.recipesTableView.reloadData()
            }

        }
        
        // Run the task
        task.resume()
        
    }
    
    func getRecipeImages() {
        
        // Create queue for running the download tasks in parallel
        let queue:OperationQueue = OperationQueue()
        
        let session:URLSession = URLSession.shared
        let domainName:String = "http://iosrecipes.com/"
        
        for i in 0..<self.recipes.count {
            let recipe:Recipe = self.recipes[i]
            
            // If there is no image url, just continue
            if recipe.imageUrl == "" {
                continue
            }
            
            // Add a download task for each recipe image
            queue.addOperation { () -> Void in
                
                // Create request to download image
                let url:URL? = URL(string: domainName + recipe.imageUrl)
                let imageRequest:URLRequest = URLRequest(url: url!)
                
                let task:URLSessionDataTask = session.dataTask(with: imageRequest, completionHandler: {
                    (data, response, error) -> Void in
                    
                    if error != nil {
                        print("There was an error downloading the image, " + (error?.localizedDescription)!)
                        return
                    }
                    
                    let httpResponse:HTTPURLResponse = (response as? HTTPURLResponse)!
                    if httpResponse.statusCode != 200 {
                        print("There was an error downloading the image, status code")
                        print("Status code = " + String(httpResponse.statusCode))
                    }
                    
                    // Update the recipe image in the main thread
                    DispatchQueue.main.async {
                        self.recipes[i].image = UIImage(data: data!)
                        
                    }
                })
                
                task.resume()
            }
        }
    }
    
    
    @IBAction func leftBarButtonClicked(_ sender: UIBarButtonItem) {

        // Assume currentLeftBarButtonItem is edit
        var setEditing:Bool = true
        var setBarButtonItem:UIBarButtonSystemItem = UIBarButtonSystemItem.done
        
        // If currentLeftBarButtonItem is actually done, finish editing
        // and delete the recipes
        if self.currentLeftBarButtonItem == UIBarButtonSystemItem.done {
            setEditing = false
            setBarButtonItem = UIBarButtonSystemItem.edit
            self.deleteRecipes(recipeIds: self.recipeIdsToDelete)
        }
        
        // Set editing
        self.recipesTableView.setEditing(setEditing, animated: setEditing)
        
        // Set left bar button
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: setBarButtonItem,
            target: self,
            action: #selector(self.leftBarButtonClicked(_:))
        )
        
        // Update current bar button and clear recipes to delete array
        self.currentLeftBarButtonItem = setBarButtonItem
        self.recipeIdsToDelete = [Int]()

    }

    
    @IBAction func addButtonClicked(_ sender: UIBarButtonItem) {
        
        // Instantiate view controller for creating new recipes
        let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newRecipeVC:UIViewController = storyBoard.instantiateViewController(withIdentifier: "createRecipeController")
        
        // Present view controller
        self.present(newRecipeVC, animated: true, completion: nil)
        
    }
    
    func deleteRecipes(recipeIds:[Int]) {
        
        if recipeIds.count == 0 {
            print("No recipes to delete")
            return
        }
        
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
            
            if error != nil {
                print("There was an error running the delete recipes task")
                print((error?.localizedDescription)!)
                return
            }
            
            do {
                // Parse response data into json
                let jsonResponse:NSDictionary = try JSONSerialization.jsonObject(with: data!, options: []) as! NSDictionary
                
                // Check status
                let status:String = String(describing: jsonResponse["status"])
                if status.lowercased().range(of: "error") != nil {
                    print("Error deleting recipes: " +
                        String(describing: jsonResponse["message"]))
                    return
                }
                
                print(jsonResponse)
            }
            catch let e as NSError {
                print("Error: couldn't convert response to valid json, " + e.localizedDescription)
                return
            }

            print("Successfully removed recipes")
            
        }
        
        task.resume()
    }


    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Initialize recipe object for RecipeViewController
        let recipeVC:RecipeViewController = segue.destination as! RecipeViewController
        recipeVC.recipe = self.selectedRecipe
    }

    // MARK: - Table View Delegate Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recipes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get reusable cell
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableCell")!
        
        // Get recipe
        let recipe:Recipe = self.recipes[indexPath.row]
        
        // Initialize label text with recipe name
        let label:UILabel? = cell.viewWithTag(1) as! UILabel?
        if let unwrappedLabel = label {
            unwrappedLabel.text = recipe.name
        }
                
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Present Recipe details for the one selected
        self.selectedRecipe = self.recipes[indexPath.row]
        self.performSegue(withIdentifier: "toRecipeView", sender: self)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            self.recipeIdsToDelete.append(self.recipes[indexPath.row].recipeId)
            self.recipes.remove(at: indexPath.row)
            self.recipesTableView.reloadData()
        }
    }
    
}

