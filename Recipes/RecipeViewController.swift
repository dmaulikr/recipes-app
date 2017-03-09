//
//  RecipeViewController.swift
//  Recipes
//
//  Created by Tushar Verma on 11/10/16.
//  Copyright © 2016 Tushar Verma. All rights reserved.
//

import UIKit
import QuartzCore

class RecipeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // UI Outlets
    @IBOutlet weak var navItem: UINavigationItem!
    
    @IBOutlet weak var recipeImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ingredientsLabel: UILabel!
    @IBOutlet weak var instructionsLabel: UILabel!

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var ingredientsTableView: UITableView!
    @IBOutlet weak var instructionsTableView: UITableView!
    
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var recipeImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ingredientsTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var instructionsTableHeightConstraint: NSLayoutConstraint!
    
    // Constants
    let defaultTableRowHeight:CGFloat = 50
    
    // Recipe object to be initialized before view is presented
    var recipe:Recipe?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Set delegates
        self.ingredientsTableView.delegate = self
        self.ingredientsTableView.dataSource = self
        self.instructionsTableView.delegate = self
        self.instructionsTableView.dataSource = self
        
        // Set content height
        let screenSize: CGRect = UIScreen.main.bounds
        self.contentViewHeightConstraint.constant = screenSize.height
        
        // Set nav bar colors
        self.navigationController?.navigationBar.barTintColor = DefaultColors.darkBlueColor
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        
        // Set table view backgrounds to clear
        self.ingredientsTableView.backgroundColor = UIColor.clear
        self.instructionsTableView.backgroundColor = UIColor.clear
        
        // Check if recipe object has been initialized
        if let unwrappedRecipe = recipe {
            
            // Initialize view with recipe details
            self.titleLabel.text = unwrappedRecipe.name
            
            if unwrappedRecipe.image != nil {
                recipeImageView.image = unwrappedRecipe.image!
                self.recipeImageHeightConstraint.constant = UIScreen.main.bounds.height / 2
                self.contentViewHeightConstraint.constant += self.recipeImageHeightConstraint.constant
            }
        
            self.descriptionTextView.text = unwrappedRecipe.recipeDescription
            self.descriptionTextView.isUserInteractionEnabled = false
            
            let numIngredients:Int = (self.recipe?.ingredients.count)!
            self.ingredientsTableHeightConstraint.constant = CGFloat(numIngredients) * self.defaultTableRowHeight
            
            let numInstructions:Int = (self.recipe?.instructions.count)!
            self.instructionsTableHeightConstraint.constant = CGFloat(numInstructions) * self.defaultTableRowHeight
            
            self.ingredientsTableView.reloadData()
            self.instructionsTableView.reloadData()
            self.view.layoutIfNeeded()
                        
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func editClicked(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "editRecipe", sender: self)        
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editRecipe" {
            let createRecipeVC = segue.destination as! CreateRecipeViewController
            createRecipeVC.recipeToEdit = self.recipe
            createRecipeVC.editingRecipe = true
        }
    }
    
    
    // MARK: - Table View Delegate Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.ingredientsTableView {
            return (recipe?.ingredients.count)!
        }
        else {
            return (recipe?.instructions.count)!
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell:UITableViewCell = UITableViewCell()
        var cellTitle:String = ""
        
        if tableView == self.ingredientsTableView {
            cell = self.ingredientsTableView.dequeueReusableCell(withIdentifier: "ingredientCell")!
            cellTitle = (self.recipe?.ingredients[indexPath.row])!
        }
        else {
            cell = self.instructionsTableView.dequeueReusableCell(withIdentifier: "instructionCell")!
            cellTitle = (self.recipe?.instructions[indexPath.row])!
        }
        
        let cellTitleLabel:UILabel = cell.viewWithTag(1) as! UILabel
        cellTitleLabel.text = cellTitle
        
        let numberLabel:UILabel = cell.viewWithTag(2) as! UILabel
        numberLabel.text = String(indexPath.row + 1)
        numberLabel.layer.masksToBounds = true
        numberLabel.layer.cornerRadius = 25 / 2
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.defaultTableRowHeight
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor.clear
    }


}
