//
//  CreateRecipeViewController.swift
//  Recipes
//
//  Created by Tushar Verma on 11/11/16.
//  Copyright © 2016 Tushar Verma. All rights reserved.
//

import UIKit

class CreateRecipeViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    // UI Outlets
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var recipeNameTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var ingredientTextField: UITextField!
    @IBOutlet weak var instructionTextField: UITextField!
    
    @IBOutlet weak var ingredientsListStackView: UIStackView!
    @IBOutlet weak var instructionsListStackView: UIStackView!
    
    @IBOutlet weak var ingredientsListHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var instructionsListHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    
    // Constants
    let saveRecipeUrl:String = "http://iosrecipes.com/saveRecipe.php"
    let editRecipeUrl:String = "http://iosrecipes.com/editRecipe.php"
    let updateRecipeUrl:String = "http://iosrecipes.com/updateRecipe.php"
    let defaultTextFieldHeight:CGFloat = 30
    
    // Recipe ingredient and instruction lists
    var ingredientsList:[StackViewTextField] = [StackViewTextField]()
    var instructionsList:[StackViewTextField] = [StackViewTextField]()
    var recipeImage:UIImage?
    
    // Member variables to be set before presenting view if editing a recipe
    var editingRecipe:Bool = false
    var recipeToEdit:Recipe?
    
    // Misc
    var activeTextField:UITextField?
    
    enum TextFieldTags:Int {
        case RECIPE = 1
        case INGREDIENT = 2
        case INSTRUCTION = 3
        case ALL = 4
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Style description text view
        let borderColor:UIColor = UIColor(displayP3Red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
    
        descriptionTextView.layer.borderWidth = 0.5
        descriptionTextView.layer.borderColor = borderColor.cgColor
        descriptionTextView.layer.cornerRadius = 5.0
        descriptionTextView.text = "Add description"
        descriptionTextView.textColor = UIColor.lightGray
        
        // Set nav bar colors
        self.navigationBar.barTintColor = DefaultColors.darkBlueColor
        self.navigationBar.tintColor = UIColor.white
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        
        // Assign self to delegates
        recipeNameTextField.delegate = self
        ingredientTextField.delegate = self
        instructionTextField.delegate = self
        descriptionTextView.delegate = self
        
        // Add keyboard listener
        self.registerForKeyboardNotifications()
        
        // Dismiss keyboard when user taps outside
        self.hideKeyboardWhenTappedAround()
        
        // If there's a recipe to edit, initialize the view with its details
        if self.recipeToEdit != nil {
            self.editingRecipe = true
            self.populateViewWithRecipeToEdit()
        }

    }
    
    deinit {
        self.deregisterFromKeyboardNotifications()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func populateViewWithRecipeToEdit() {
        self.recipeNameTextField.text = self.recipeToEdit?.name
        self.descriptionTextView.text = self.recipeToEdit?.recipeDescription
        
        // Add each ingredient to view
        var ingredients:[String] = (self.recipeToEdit?.ingredients)!
        for i in 0 ..< ingredients.count {
            let textField:StackViewTextField = self.addStackViewTextField(textFieldText: ingredients[i], stackView: self.ingredientsListStackView, heightConstraint: self.ingredientsListHeightConstraint)
            
            // Set textfields ingredientId in order to add to ingredientToIdMap when saving recipe
            textField.ingredientId = self.recipeToEdit?.ingredientToIdMap[ingredients[i]]
            
            // Add to ingredients array
            self.ingredientsList.append(textField)

        }
        
        // Add each instruction to view
        var instructions:[String] = (self.recipeToEdit?.instructions)!
        for i in 0 ..< instructions.count {
            let textField:StackViewTextField = self.addStackViewTextField(textFieldText: instructions[i], stackView: self.instructionsListStackView, heightConstraint: self.instructionsListHeightConstraint)
            
            // Set textfields instructionId in order to add to instructionToIdMap when saving recipe
            textField.instructionId = self.recipeToEdit?.instructiontToIdMap[instructions[i]]
            
            // Add to instructions array
            self.instructionsList.append(textField)
        }

    }
    
    @IBAction func addImageClicked(_ sender: UIButton) {
        
    }
    
    @IBAction func addIngredientClicked(_ sender: UIButton) {
        
        if self.ingredientTextField.text == "" {
            return
        }
        
        // Add to view
        let textField:StackViewTextField = self.addStackViewTextField(textFieldText: self.ingredientTextField.text!, stackView: self.ingredientsListStackView, heightConstraint: self.ingredientsListHeightConstraint)
        
        // Add to ingredients array
        self.ingredientsList.append(textField)

        self.ingredientTextField.text = ""
        self.view.layoutIfNeeded()
        
    }
    
    @IBAction func addInstructionClicked(_ sender: UIButton) {
        
        if self.instructionTextField.text == "" {
            return
        }
        
        let textField:StackViewTextField = self.addStackViewTextField(textFieldText: self.instructionTextField.text!, stackView: self.instructionsListStackView, heightConstraint: self.instructionsListHeightConstraint)
        
        // Add to instructions array
        self.instructionsList.append(textField)
        
        self.instructionTextField.text = ""
        self.view.layoutIfNeeded()
        
    }
    
    func addStackViewTextField(textFieldText:String, stackView:UIStackView, heightConstraint: NSLayoutConstraint) -> StackViewTextField {
        
        // Initialize stack view text field
        // Use StackViewTextField so we can associate an id with it later
        let newTextField:StackViewTextField = StackViewTextField()
        newTextField.text = textFieldText
        newTextField.borderStyle = UITextBorderStyle.none
        
        // Add to view
        stackView.addArrangedSubview(newTextField)
        heightConstraint.constant += self.defaultTextFieldHeight
        self.contentViewHeightConstraint.constant += self.defaultTextFieldHeight
        
        return newTextField
    }

    
    @IBAction func cancelRecipeClicked(_ sender: UIBarButtonItem) {
        self.presentNavigationController()
    }
    
    
    @IBAction func saveRecipeClicked(_ sender: UIBarButtonItem) {
        // Create recipe object to save
        let recipe:Recipe = Recipe()
        
        recipe.name = recipeNameTextField.text!
        recipe.recipeDescription = descriptionTextView.text
        
        // Loop through each ingredient
        for i in 0 ..< self.ingredientsList.count {
            let ingredient:StackViewTextField = self.ingredientsList[i]
            
            // Add ingredient to recipe
            recipe.ingredients.append(ingredient.text!)
            
            // If the ingredient has an id, add it to the map
            // This map is needed by the php script to update existing ingredients
            if ingredient.ingredientId != nil {
                recipe.ingredientToIdMap[ingredient.text!] = ingredient.ingredientId!
            }
        }
        
        // Loop through each instruction
        for i in 0 ..< self.instructionsList.count {
            let instruction:StackViewTextField = self.instructionsList[i]
            
            // Add instruction to recipe
            recipe.instructions.append(instruction.text!)
            
            // If the instruction has an id, add it to the map
            // This map is needed by the php script to update existing instructions
            if instruction.instructionId != nil {
                recipe.instructiontToIdMap[instruction.text!] = instruction.instructionId
            }
        }
        
        // Add the image, if one has been added
        if self.recipeImage != nil {
            recipe.image = self.recipeImage
        }
        
        // Save the recipeId if this is recipe is being edited
        if self.editingRecipe && self.recipeToEdit != nil {
            recipe.recipeId = (self.recipeToEdit?.recipeId)!
        }
        
        // Save the recipe as a json data object
        var data:Data?
        do {
        
            let json:[String:AnyObject] = [
                "recipe_id" : recipe.recipeId as AnyObject,
                "name" : recipe.name as AnyObject,
                "description" : recipe.recipeDescription as AnyObject,
                "ingredients" : recipe.ingredients as AnyObject,
                "instructions" : recipe.instructions as AnyObject,
                "ingredientToIdMap" : recipe.ingredientToIdMap as AnyObject,
                "instructionToIdMap" : recipe.instructiontToIdMap as AnyObject
            ]
                        
            data = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted)
            
        }
        catch let e as NSError {
            NSLog("Error: couldn't convert recipe object to valid json, " + e.localizedDescription)
            return
        }
        
        
        // Create url object
        var url:URL?
        if self.editingRecipe {
            url = URL(string: self.updateRecipeUrl)!
        }
        else {
            url = URL(string: self.saveRecipeUrl)!
        }
        
        // Create and initialize request
        var request:URLRequest = URLRequest(url: url!)
        
        request.httpMethod = "POST"
        request.httpBody = data!
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create task to save or update the recipe
        let task:URLSessionDataTask = URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            
            // Log status result of task
            if error != nil {
                NSLog("There was an error running the task to save the recipe")
                NSLog((error?.localizedDescription)!)
                return
            }
            
            let httpResponse = response as! HTTPURLResponse
            if httpResponse.statusCode == 200 {
                NSLog("Recipe inserted successfully")
            }
            else {
                NSLog(String(format: "Error: Status code: %d", httpResponse.statusCode))
            }
            
            // Go back to ViewController
            DispatchQueue.main.async {
                self.presentNavigationController()
            }
            
        })
        
        
        // Run the task
        task.resume()

    }
    
    // MARK: - Utility functions
    
    func isValidJSON(json: AnyObject) -> Bool {
        return JSONSerialization.isValidJSONObject(json)
    }
    
    func presentNavigationController() {
        let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let recipesVC:UIViewController = storyBoard.instantiateViewController(withIdentifier: "navigationController")
        
        self.present(recipesVC, animated: false, completion: nil)
    }
    
    // MARK: - Keyboard functions
    
    func registerForKeyboardNotifications(){
        //Adding notifies on keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func deregisterFromKeyboardNotifications(){
        //Removing notifies on keyboard appearing
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWasShown(notification: NSNotification){
        // Calculate the keyboards size
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        
        // Define the insets for the content to be displayed above the keyboard
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize!.height + 10, 0.0)
        
        // Set the scroll view to the new insets
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        
        // Find the CGRect of the view above the keyboard
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        
        // Scroll the active text field above the keyboard if it's hidden
        if let activeField = self.activeTextField {
            if (!aRect.contains(activeField.frame.origin)){
                self.scrollView.scrollRectToVisible(activeField.frame, animated: true)
            }
        }
    }
    
    func keyboardWillBeHidden(notification: NSNotification){
        //Once keyboard disappears, restore original positions
        self.scrollView.contentInset = UIEdgeInsets.zero
        self.view.endEditing(true)
    }
    
    
    // MARK: - Text Field Delegate Methods
    func textFieldDidBeginEditing(_ textField: UITextField){
        self.activeTextField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField){
        self.activeTextField = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(textFieldTag: textField.tag)
        return true
    }
    
    func endEditing(textFieldTag:Int) {
        // Dismiss the appropriate text field keyboard
        UIView.animate(withDuration: 0.25, animations: {
            switch(textFieldTag) {
                case TextFieldTags.RECIPE.rawValue:
                    self.recipeNameTextField.endEditing(true)
                    self.recipeNameTextField.resignFirstResponder()
                
                case TextFieldTags.INGREDIENT.rawValue:
                    self.ingredientTextField.endEditing(true)
                    self.ingredientTextField.resignFirstResponder()
                
                case TextFieldTags.INSTRUCTION.rawValue:
                    self.instructionTextField.endEditing(true)
                    self.instructionTextField.resignFirstResponder()
                
                default:
                    NSLog("There was an unrecognized text field tag, dismissing all")
                    self.recipeNameTextField.endEditing(true)
                    self.recipeNameTextField.resignFirstResponder()
                    self.ingredientTextField.endEditing(true)
                    self.ingredientTextField.resignFirstResponder()
                    self.instructionTextField.endEditing(true)
                    self.instructionTextField.resignFirstResponder()
            }
        })
        
    }
    
    // MARK: - Text View Delegate Methods
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if(descriptionTextView.text == "Add description") {
            descriptionTextView.text = ""
        }
        
        descriptionTextView.textColor = UIColor.black
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if(textView.text == "") {
            descriptionTextView.text = "Add description"
            descriptionTextView.textColor = UIColor.lightGray
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - StackViewTextField Inner Class
    class StackViewTextField: UITextField {
        var ingredientId:Int?
        var instructionId:Int?
        
    }
    
    // TODO: Change to struct
//    struct StackViewTextField {
//        var textField:UITextField = UITextField()
//        var ingredientId:Int?
//        var instructionId:Int?
//    }
    

}
