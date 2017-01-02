//
//  RecipeViewController.swift
//  Recipes
//
//  Created by Tushar Verma on 11/10/16.
//  Copyright © 2016 Tushar Verma. All rights reserved.
//

import UIKit

class RecipeViewController: UIViewController {
    
    // UI Outlets
    @IBOutlet weak var navItem: UINavigationItem!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ingredientsLabel: UILabel!
    @IBOutlet weak var instructionsLabel: UILabel!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var ingredientsStackView: UIStackView!
    @IBOutlet weak var instructionsStackView: UIStackView!
    
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ingredientsListHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var instructionsListHeightConstraint: NSLayoutConstraint!
    
    // Recipe object to be initialized before view is presented
    var recipe:Recipe?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Check if recipe object has been initialized
        if let unwrappedRecipe = recipe {
            
            // Initialize view with recipe details
            self.titleLabel.text = unwrappedRecipe.name
        
            self.descriptionTextView.text = unwrappedRecipe.recipeDescription
            self.descriptionTextView.isUserInteractionEnabled = false
            
            for i in 0 ..< unwrappedRecipe.ingredients.count {
                addLabelToView(labelText: unwrappedRecipe.ingredients[i], stackView: self.ingredientsStackView, heightConstraint: self.ingredientsListHeightConstraint)
            }
            
            for i in 0 ..< unwrappedRecipe.instructions.count {
                addLabelToView(labelText: unwrappedRecipe.instructions[i], stackView: self.instructionsStackView, heightConstraint: self.instructionsListHeightConstraint)
            }
            
            self.view.layoutIfNeeded()
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addLabelToView(labelText:String, stackView:UIStackView, heightConstraint: NSLayoutConstraint) {
        
        if labelText == "" {
            return
        }
        
        // Initialize label
        let newLabel:UILabel = UILabel()
        newLabel.text = labelText
        
        // Add to view
        stackView.addArrangedSubview(newLabel)
        heightConstraint.constant += 30 // 30 is default height for label
        self.contentViewHeightConstraint.constant += 30
    }
    
    
    @IBAction func editClicked(_ sender: UIBarButtonItem) {
        // Instantiate view controller for creating new recipes
        let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let editRecipeVC:CreateRecipeViewController = storyBoard.instantiateViewController(withIdentifier: "createRecipeController") as! CreateRecipeViewController
        
        // Initialize recipe to edit
        editRecipeVC.recipeToEdit = self.recipe
        editRecipeVC.editingRecipe = true
        
        // Present view 
        self.present(editRecipeVC, animated: true, completion: nil)
        
    }
    

    /*
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

     }
    */
    

}
