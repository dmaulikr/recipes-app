//
//  CreateRecipeViewController.swift
//  Recipes
//
//  Created by Tushar Verma on 11/11/16.
//  Copyright © 2016 Tushar Verma. All rights reserved.
//

import UIKit

class CreateRecipeViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    
    @IBOutlet weak var recipeNameTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var ingredientTextField: UITextField!
    @IBOutlet weak var instructionTextField: UITextField!
    
    @IBOutlet weak var ingredientsListStackView: UIStackView!
    @IBOutlet weak var instructionsListStackView: UIStackView!
    
    @IBOutlet weak var ingredientsListHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var instructionsListHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    
    var saveRecipeUrl:String = "http://iosrecipes.com/saveRecipe.php"
    var editRecipeUrl:String = "http://iosrecipes.com/editRecipe.php"
    var updateRecipeUrl:String = "http://iosrecipes.com/updateRecipe.php"
    
    var ingredientsList:[StackViewTextField] = [StackViewTextField]()
    var instructionsList:[StackViewTextField] = [StackViewTextField]()
    var recipeImage:UIImage?
    
    var editingRecipe:Bool = false
    var recipeToEdit:Recipe?
    
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
        
        // Assign self to delegates
        recipeNameTextField.delegate = self
        ingredientTextField.delegate = self
        instructionTextField.delegate = self
        descriptionTextView.delegate = self
        
        // Add keyboard listener
        NotificationCenter.default.addObserver(self, selector:#selector(self.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        if self.recipeToEdit != nil {
            self.editingRecipe = true
            self.populateViewWithRecipeToEdit()
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let frame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        NSLog(frame.debugDescription)
        
        // do stuff with the frame...
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.endEditing(textFieldTag: TextFieldTags.ALL.rawValue)
    }
    
    func populateViewWithRecipeToEdit() {
        print("populating recipe to edit")
        self.recipeNameTextField.text = self.recipeToEdit?.name
        self.descriptionTextView.text = self.recipeToEdit?.recipeDescription
        
        var ingredients:[String] = (self.recipeToEdit?.ingredients)!
        for i in 0 ..< ingredients.count {
            let textField:StackViewTextField = self.addStackViewTextField(textFieldText: ingredients[i], stackView: self.ingredientsListStackView, heightConstraint: self.ingredientsListHeightConstraint)
            
            textField.ingredientId = self.recipeToEdit?.ingredientToIdMap[ingredients[i]]
            self.ingredientsList.append(textField)

        }
        
        var instructions:[String] = (self.recipeToEdit?.instructions)!
        for i in 0 ..< instructions.count {
            let textField:StackViewTextField = self.addStackViewTextField(textFieldText: instructions[i], stackView: self.instructionsListStackView, heightConstraint: self.instructionsListHeightConstraint)
            
            textField.instructionId = self.recipeToEdit?.instructiontToIdMap[instructions[i]]
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
        
        // Add to array
        self.ingredientsList.append(textField)

        
        self.ingredientTextField.text = ""
        self.view.layoutIfNeeded()
        
    }
    
    @IBAction func addInstructionClicked(_ sender: UIButton) {
        
        if self.instructionTextField.text == "" {
            return
        }
        
        let textField:StackViewTextField = self.addStackViewTextField(textFieldText: self.instructionTextField.text!, stackView: self.instructionsListStackView, heightConstraint: self.instructionsListHeightConstraint)
        
        // Add to array
        self.instructionsList.append(textField)
        
        self.instructionTextField.text = ""
        self.view.layoutIfNeeded()
        
    }
    
    func addStackViewTextField(textFieldText:String, stackView:UIStackView, heightConstraint: NSLayoutConstraint) -> StackViewTextField {
        
        // Initialize text view
        let newTextField:StackViewTextField = StackViewTextField()
        newTextField.text = textFieldText
        newTextField.borderStyle = UITextBorderStyle.none
        
        // Add to view
        stackView.addArrangedSubview(newTextField)
        heightConstraint.constant += 30 // 30 is default height for label
        self.contentViewHeightConstraint.constant += 30
        
        return newTextField
    }

    
    @IBAction func cancelRecipeClicked(_ sender: UIBarButtonItem) {
        self.presentNavigationController()
    }
    
    
    @IBAction func saveRecipeClicked(_ sender: UIBarButtonItem) {
        let recipe:Recipe = Recipe()
        
        recipe.name = recipeNameTextField.text!
        recipe.recipeDescription = descriptionTextView.text
        

        for i in 0 ..< self.ingredientsList.count {
            let ingredient:StackViewTextField = self.ingredientsList[i]
            
            recipe.ingredients.append(ingredient.text!)
            if ingredient.ingredientId != nil {
                recipe.ingredientToIdMap[ingredient.text!] = ingredient.ingredientId!
            }
        }
        
        for i in 0 ..< self.instructionsList.count {
            let instruction:StackViewTextField = self.instructionsList[i]
            
            recipe.instructions.append(instruction.text!)
            if instruction.instructionId != nil {
                recipe.instructiontToIdMap[instruction.text!] = instruction.instructionId
            }
        }
        
        if self.recipeImage != nil {
            recipe.image = self.recipeImage
        }
        
        if self.editingRecipe && self.recipeToEdit != nil {
            recipe.recipeId = (self.recipeToEdit?.recipeId)!
        }
        
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
        
        
        // Create a request
        var url:URL?
        if self.editingRecipe {
            url = URL(string: self.updateRecipeUrl)!
        }
        else {
            url = URL(string: self.saveRecipeUrl)!
        }
        
        var request:URLRequest = URLRequest(url: url!)
        
        request.httpMethod = "POST"
        request.httpBody = data!
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task:URLSessionDataTask = URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            
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
            
            DispatchQueue.main.async {
                self.presentNavigationController()
            }
            
        })
        
        
        // Run the task
        task.resume()

    }
    
    func isValidJSON(json: AnyObject) -> Bool {
        return JSONSerialization.isValidJSONObject(json)
    }
    
    func presentNavigationController() {
        let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let recipesVC:UIViewController = storyBoard.instantiateViewController(withIdentifier: "navigationController")
        
        self.present(recipesVC, animated: false, completion: nil)
    }
    
    
    // MARK: - Text Field Delegate Methods
    func textFieldDidBeginEditing(_ textField: UITextField) {

    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(textFieldTag: textField.tag)
        return true
    }
    
    func endEditing(textFieldTag:Int) {
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
    
    func endEditing(textView:UITextView) {
        // TODO: dismiss keyboard
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

}
