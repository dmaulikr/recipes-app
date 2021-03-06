//
//  CreateRecipeViewController.swift
//  Recipes
//
//  Created by Tushar Verma on 11/11/16.
//  Copyright © 2016 Tushar Verma. All rights reserved.
//

import UIKit
import Fusuma

class CreateRecipeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FusumaDelegate {
    
    // UI Outlets
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var recipeImageView: UIImageView!
    @IBOutlet weak var recipeFiltersStackView: UIStackView!
    @IBOutlet weak var recipeNameTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var ingredientTextField: UITextField!
    @IBOutlet weak var instructionTextView: UITextView!
    @IBOutlet weak var ingredientsTableView: UITableView!
    @IBOutlet weak var instructionsTableView: UITableView!
    
    @IBOutlet weak var deleteImageButton: UIButton!
    @IBOutlet weak var editIngredientButton: UIButton!
    @IBOutlet weak var editInstructionButton: UIButton!
    
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var recipeImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var recipeFiltersHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ingredientsTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var instructionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var instructionsTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableMarginConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var descriptionPlaceholder: UILabel!
    @IBOutlet weak var instructionPlaceholder: UILabel!
    
    
    // Constants
    let tableCellFontSize:CGFloat = 20 // The max font size we'll probably use
    let defaultTableRowHeight:CGFloat = 50
    
    // Member variables to be set before presenting view if editing a recipe
    var editingRecipe:Bool = false
    var recipeToEdit:Recipe?
    // array of table row to its associated id (ids are needed when users edit ingredients/instructions)
    var ingredientRowIds:[Int] = [Int]()
    var instructionRowIds:[Int] = [Int]()
    
    // Misc
    let recipesService:RecipesService = RecipesService()
    let alertControllerUtil:AlertControllerUtil = AlertControllerUtil()
    
    var fusama:FusumaViewController = FusumaViewController() // Image Picker Controller
    
    var ingredients:[String] = [String]()
    var ingredientRowHeights:[String:CGFloat] = [String:CGFloat]()
    var ingredientIdsToDelete:[Int] = [Int]()
    
    var instructions:[String] = [String]()
    var instructionRowHeights:[String:CGFloat] = [String:CGFloat]()
    var instructionIdsToDelete:[Int] = [Int]()
    
    lazy var tableWidth:CGFloat = {
        return UIScreen.main.bounds.width - (2 * self.tableMarginConstraint.constant)
    }()
    
    var activeTextField:UITextField?
    
    // Flags to figure out how to save image
    var newRecipeImageSelected:Bool = false
    var imageDeleted:Bool = false
    
    let filtersToIntensity:[String:Float?] = [
        "CIPhotoEffectChrome" : nil,
        "CIPhotoEffectFade" : nil,
        "CIPhotoEffectInstant" : nil,
        "CIPhotoEffectProcess": nil,
        "CIPhotoEffectTonal": nil,
        "CIPhotoEffectTransfer": nil,
        "CISepiaTone": 0.5,
        "CIVignette" : 1
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set table view backgrounds to clear
        self.ingredientsTableView.backgroundColor = UIColor.clear
        self.instructionsTableView.backgroundColor = UIColor.clear

        // Style text views
        self.descriptionTextView.config()
        self.instructionTextView.config()
        
        // Set properties of fusama image picker controller
        fusama.hasVideo = false
        
        // Assign self to delegates and datasources
        fusama.delegate = self

        recipeNameTextField.delegate = self
        ingredientTextField.delegate = self
        descriptionTextView.delegate = self
        ingredientsTableView.delegate = self
        instructionTextView.delegate = self
        instructionsTableView.delegate = self
        
        ingredientsTableView.dataSource = self
        instructionsTableView.dataSource = self
        
        // Add keyboard listener
        self.registerForKeyboardNotifications()
        
        // Add text field targets to change font dynamically
        self.recipeNameTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)),
                            for: UIControlEvents.editingChanged)
        self.ingredientTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)),
                                           for: UIControlEvents.editingChanged)
        
        // Dismiss keyboard when user taps outside
        self.hideKeyboardWhenTappedAround()
        
        // Hide edit ingredient/instruction button
        self.deleteImageButton.alpha = 0
        self.editIngredientButton.alpha = 0
        self.editInstructionButton.alpha = 0
        
        // If there's a recipe to edit, initialize the view with its details
        if self.recipeToEdit != nil {
            self.editingRecipe = true
            
            if self.recipeToEdit?.image != nil {
                self.deleteImageButton.alpha = 1
            }
            
            if (self.recipeToEdit?.ingredients.count)! > 0 {
                self.editIngredientButton.alpha = 1
            }
            
            if (self.recipeToEdit?.instructions.count)! > 0 {
                self.editInstructionButton.alpha = 1
            }
            
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAllRecipes" {
            // Let the view controller know that it doesn't need to make a remote call to load the recipes
            let tabBarController = segue.destination as! UITabBarController
            let navigationController = tabBarController.viewControllers?.first as! UINavigationController
            let viewController = navigationController.viewControllers.first as! ViewController
            viewController.loadRecipes = false
        }
    }
    
    
    func populateViewWithRecipeToEdit() {
        self.recipeNameTextField.text = self.recipeToEdit?.name
        
        if self.recipeToEdit?.recipeDescription != "" {
            self.descriptionTextView.text = self.recipeToEdit?.recipeDescription
            self.descriptionViewHeightConstraint.constant = self.descriptionTextView.getSizeThatFits().height
            self.descriptionPlaceholder.alpha = 0
        }
        
        // Add each ingredient to view
        let recipeIngredients:[String] = (self.recipeToEdit?.ingredients)!
        for i in 0 ..< recipeIngredients.count {
        
            // Add to ingredients array
            let ingredient:String = recipeIngredients[i]
            self.ingredients.append(ingredient)
            
            let height = ingredient.calculateHeight(inWidth: self.tableWidth, withFontSize: self.tableCellFontSize)
            self.ingredientRowHeights[ingredient] = (height > self.defaultTableRowHeight) ? height : self.defaultTableRowHeight
            
            // Add to row ids array
            self.ingredientRowIds.append((self.recipeToEdit?.ingredientToIdMap[ingredient])!)
            
            // Adjust height constraints
            self.ingredientsTableHeightConstraint.constant += self.ingredientRowHeights[ingredient]!
            self.contentViewHeightConstraint.constant += self.ingredientRowHeights[ingredient]!
        }
        
        // Add each instruction to the table
        let recipeInstructions:[String] = (self.recipeToEdit?.instructions)!
        for i in 0 ..< recipeInstructions.count {
            
            // Add to instructions array
            let instruction:String = recipeInstructions[i]
            self.instructions.append(instruction)
            
            let height = instruction.calculateHeight(inWidth: self.tableWidth, withFontSize: self.tableCellFontSize)
            self.instructionRowHeights[instruction] = (height > self.defaultTableRowHeight) ? height : self.defaultTableRowHeight
            
            // Add to row ids array
            self.instructionRowIds.append((self.recipeToEdit?.instructionToIdMap[instruction])!)
            
            // Adjust height constraints
            self.instructionsTableHeightConstraint.constant += self.instructionRowHeights[instruction]!
            self.contentViewHeightConstraint.constant += self.instructionRowHeights[instruction]!
        }
        
        if let image = self.recipeToEdit?.image {
            addImageToView(image: image)
        }
        
        self.ingredientsTableView.reloadData()
        self.instructionsTableView.reloadData()

    }
    
    @IBAction func addImageClicked(_ sender: UIButton) {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            self.present(self.fusama, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func deleteImageClicked(_ sender: UIButton) {
        let myAlert:UIAlertController = UIAlertController(title: "Are you sure you want to delete the image?", message: "", preferredStyle: UIAlertControllerStyle.alert)
        
        let firstAction:UIAlertAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (alertAction:UIAlertAction!) in
            
            self.recipeImageView.image = nil
            self.contentViewHeightConstraint.constant -= self.recipeImageHeightConstraint.constant
            self.recipeImageHeightConstraint.constant = 0
            
            for view in self.recipeFiltersStackView.arrangedSubviews {
                self.recipeFiltersStackView.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
            
            self.contentViewHeightConstraint.constant -= self.recipeFiltersHeightConstraint.constant
            self.recipeFiltersHeightConstraint.constant = 0
            
            // If editing and started with a recipe, user deleted it
            if self.editingRecipe && self.recipeToEdit?.image != nil {
                self.imageDeleted = true
            }
            
            // Whether the user is editing or not, there's no new image
            self.newRecipeImageSelected = false
            self.deleteImageButton.alpha = 0

        })
        
        
        let secondAction:UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (alertAction:UIAlertAction!) in
                print("cancel button clicked")
        })
        
        myAlert.addAction(firstAction)
        myAlert.addAction(secondAction)
        
        self.present(myAlert, animated: true, completion: nil)

    }
    
    @IBAction func addIngredientClicked(_ sender: UIButton) {
        
        if self.ingredientTextField.text == "" {
            self.ingredientTextField.becomeFirstResponder()
            return
        }
        
        let ingredient = self.ingredientTextField.text!
        self.ingredients.append(ingredient)
        
        let height = ingredient.calculateHeight(inWidth: self.tableWidth, withFontSize: self.tableCellFontSize)
        self.ingredientRowHeights[ingredient] = (height > self.defaultTableRowHeight) ? height : self.defaultTableRowHeight
        
        self.ingredientTextField.text = ""
        
        self.ingredientsTableHeightConstraint.constant += self.ingredientRowHeights[ingredient]!
        self.contentViewHeightConstraint.constant += self.ingredientRowHeights[ingredient]!
        self.ingredientsTableView.reloadData()
        
        self.editIngredientButton.alpha = 1
    }
    
    
    @IBAction func editIngredientClicked(_ sender: UIButton) {
        self.ingredientsTableView.setEditing(!self.ingredientsTableView.isEditing, animated: true)
    }
    
    
    @IBAction func addInstructionClicked(_ sender: UIButton) {
        
        if self.instructionTextView.isEmpty() {
            self.instructionTextView.becomeFirstResponder()
            return
        }
        
        let instruction = self.instructionTextView.text!
        self.instructions.append(instruction)
        
        let height = instruction.calculateHeight(inWidth: self.tableWidth, withFontSize: self.tableCellFontSize)
        self.instructionRowHeights[instruction] = (height > self.defaultTableRowHeight) ? height : self.defaultTableRowHeight
        
        self.instructionTextView.text = ""
        self.instructionPlaceholder.alpha = 1
        
        self.instructionViewHeightConstraint.constant = self.instructionTextView.getSizeThatFits().height
        self.instructionsTableHeightConstraint.constant += self.instructionRowHeights[instruction]!
        self.contentViewHeightConstraint.constant += self.instructionRowHeights[instruction]!
        self.instructionsTableView.reloadData()
        
        self.editInstructionButton.alpha = 1
    }
    
    
    @IBAction func editInstructionClicked(_ sender: UIButton) {
        self.instructionsTableView.setEditing(!self.instructionsTableView.isEditing, animated: true)
    }
    
    
    @IBAction func saveRecipeClicked(_ sender: UIBarButtonItem) {
        
        self.startActivityIndicators()
        
        // If no image, or it's not a new one, just save the data
        if self.recipeImageView.image == nil || !self.newRecipeImageSelected {
            saveRecipeData(imageId: nil, imageUrl: nil, updateExistingRecipe: self.editingRecipe, deleteImage: self.imageDeleted)
            return
        }
        
        print("saving image")
        
        // Otherwise, we want to save the image and then save the recipe data on success
        self.recipesService.saveRecipeImage(image: self.recipeImageView.image!) { (success, json) in
            if !success {
                print("There was an error saving the recipe image")
                DispatchQueue.main.async {
                    self.endActivityIndicators()
                    self.alertControllerUtil.displayErrorAlert(presentOn: self, actionToRetry: {
                        self.saveRecipeClicked(sender)
                    })
                }
                return
            }
            
            let imageId:Int? = json["image_id"] as? Int
            let imageUrl:String? = json["image_url"] as? String
            print("successfully saved image, imageId = \(imageId), imageUrl = \(imageUrl)")

            // Go back to ViewController
            DispatchQueue.main.async {
                self.saveRecipeData(imageId: imageId, imageUrl: imageUrl, updateExistingRecipe: self.editingRecipe,
                                    deleteImage: false)
            }
        }
    }
    
    func saveRecipeData(imageId:Int?, imageUrl:String?, updateExistingRecipe: Bool, deleteImage:Bool) {
        
        // Create recipe object to save
        let recipe:Recipe = Recipe()
        
        recipe.name = recipeNameTextField.text!
        
        if !self.descriptionTextView.isEmpty() {
            recipe.recipeDescription = descriptionTextView.text
        }
        
        for i in 0 ..< self.ingredients.count {
            
            let ingredient:String = self.ingredients[i]
            recipe.ingredients.append(ingredient)
            
            // If the ingredient row has an id, add it to ingredientToId map
            if i < self.ingredientRowIds.count {
                recipe.ingredientToIdMap[ingredient] = self.ingredientRowIds[i]
            }
        }
        
        for i in 0 ..< self.instructions.count {
            
            let instruction:String = self.instructions[i]
            recipe.instructions.append(instruction)
            
            // If the instruction row has an id, add it to the instructionToId map
            if i < self.instructionRowIds.count {
                recipe.instructionToIdMap[instruction] = self.instructionRowIds[i]
            }
            
        }
        
        if self.editingRecipe {
            recipe.recipeId = (recipeToEdit?.recipeId)!
            recipesService.updateRecipe(recipe: recipe, imageId: imageId, deleteImage: deleteImage, ingredientsToDelete: self.ingredientIdsToDelete, instructionsToDelete: self.instructionIdsToDelete, completionHandler: {
                (success, json) in
                
                if !success {
                    print("There was an error saving the recipe data")
                    DispatchQueue.main.async {
                        self.endActivityIndicators()
                        self.alertControllerUtil.displayErrorAlert(presentOn: self, actionToRetry: {
                            self.saveRecipeData(imageId: imageId, imageUrl: imageUrl, updateExistingRecipe: updateExistingRecipe, deleteImage: deleteImage)
                        })
                    }
                    return
                }
                
                print("Recipe successfully updated")
                self.saveRecipesCallback(recipe: recipe, imageUrl: imageUrl, json: json)
                
            })
        }
        else {
            recipesService.createRecipe(recipe: recipe, imageId: imageId, completionHandler: { (success, json) in
                if !success {
                    print("There was an error saving the recipe data")
                    DispatchQueue.main.async {
                        self.endActivityIndicators()
                        self.alertControllerUtil.displayErrorAlert(presentOn: self, actionToRetry: {
                            self.saveRecipeData(imageId: imageId, imageUrl: imageUrl, updateExistingRecipe: updateExistingRecipe, deleteImage: deleteImage)
                        })
                    }
                    return
                }
                
                print("Recipe successfully saved")
                self.saveRecipesCallback(recipe: recipe, imageUrl: imageUrl, json: json)
            })
        }
    }
    
    // MARK: - Utility functions
    
    func saveRecipesCallback(recipe:Recipe, imageUrl:String?, json:NSDictionary) {
        
        // Set the following recipe properties so it can by saved to the file system
        recipe.image = self.recipeImageView.image
        if let imageUrl = imageUrl {
            recipe.imageUrl = imageUrl
        }
        
        let recipeId:Int? = json["recipe_id"] as? Int
        if let recipeId = recipeId {
            recipe.recipeId = recipeId
        }
        
        let ingredientsMap:NSDictionary? = (json["ingredient_to_id_map"])! as? NSDictionary
        if ingredientsMap != nil {
            for (key, value) in ingredientsMap! {
                recipe.ingredientToIdMap[key as! String] = value as? Int
            }
        }
        
        let instructionsMap:NSDictionary? = (json["instruction_to_id_map"])! as? NSDictionary
        if instructionsMap != nil {
            for (key, value) in instructionsMap! {
                recipe.instructionToIdMap[key as! String] = value as? Int
            }
        }
        
        // Go back to ViewController
        DispatchQueue.main.async {
            let fileManagerService = RecipesFileManagerUtil()
            let recipesFile = UserDefaults.standard.object(forKey: Config.UserDefaultsKey.recipesFilePathKey) as! String
            
            if self.editingRecipe {
                recipe.recipeId = (self.recipeToEdit?.recipeId)!
                fileManagerService.overwriteRecipe(withRecipeId: recipe.recipeId, newRecipe: recipe, filePath: recipesFile)
            }
            else {
                recipe.recipeId = (json["recipe_id"])! as! Int
                fileManagerService.saveRecipesToFile(recipesToSave: [recipe], filePath: recipesFile, appendToFile: true)
            }
            
            self.performSegue(withIdentifier: "toAllRecipes", sender: self)
        }
    }
    
    func addImageToView(image: UIImage) {
        self.recipeImageView.image = image
        self.recipeImageHeightConstraint.constant = UIScreen.main.bounds.height / 2
        self.contentViewHeightConstraint.constant += self.recipeImageHeightConstraint.constant
        createFilters(imageToFilter: self.recipeImageView)
    }
    
    func createFilters(imageToFilter:UIImageView) {
        
        self.recipeFiltersHeightConstraint.constant = UIScreen.main.bounds.height / 3
        self.contentViewHeightConstraint.constant += UIScreen.main.bounds.height / 3
            
        let firstRowStackView = UIStackView()
        firstRowStackView.axis = UILayoutConstraintAxis.horizontal
        firstRowStackView.distribution = UIStackViewDistribution.fillEqually
        firstRowStackView.spacing = 5
        firstRowStackView.backgroundColor = UIColor.black
            
        let secondRowStackView = UIStackView()
        secondRowStackView.axis = UILayoutConstraintAxis.horizontal
        secondRowStackView.distribution = UIStackViewDistribution.fillEqually
        secondRowStackView.spacing = 5
        secondRowStackView.backgroundColor = UIColor.black
        
        var currentStackView:UIStackView = firstRowStackView
        let imagesPerRow = filtersToIntensity.count / 2
        var imageNumber:Int = 0
        
        for (filter, intensity) in filtersToIntensity {
            print(filter)
            
            let image:UIImageView = UIImageView(image: imageToFilter.image)
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageFilterTapped(tapGestureRecognizer:)))
            image.isUserInteractionEnabled = true
            image.addGestureRecognizer(tapGestureRecognizer)
            image.contentMode = UIViewContentMode.scaleAspectFit
            
            addFilter(imageToFilter: image, filter: filter, intensity: intensity)
            
            currentStackView.addArrangedSubview(image)
            
            imageNumber += 1
            if imageNumber == imagesPerRow {
                imageNumber = 0
                currentStackView = secondRowStackView
            }
        }
        
        for view in self.recipeFiltersStackView.arrangedSubviews {
            self.recipeFiltersStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        self.recipeFiltersStackView.addArrangedSubview(firstRowStackView)
        self.recipeFiltersStackView.addArrangedSubview(secondRowStackView)

        
    }
    
    func addFilter(imageToFilter:UIImageView, filter:String, intensity:Float?) {
        
        guard let image = imageToFilter.image, let cgimg = image.cgImage else {
            print("imageView doesn't have an image!")
            return
        }
        
        // Create context which uses an API that interacts directly with the GPU
        let openGLContext = EAGLContext(api: .openGLES2)
        let context = CIContext(eaglContext: openGLContext!)
        
        let coreImage = CIImage(cgImage: cgimg)
        
        let filter = CIFilter(name: filter)
        filter?.setValue(coreImage, forKey: kCIInputImageKey)
        if intensity != nil {
            filter?.setValue(intensity!, forKey: kCIInputIntensityKey)
        }
        
        if let output = filter?.value(forKey: kCIOutputImageKey) as? CIImage {
            let cgimgresult = context.createCGImage(output, from: output.extent)
            
            // Initialize with original image orientation since the filtering can change it sometimes
            let originalOrientation:UIImageOrientation = (imageToFilter.image?.imageOrientation)!
            let filteredImage = UIImage(cgImage: cgimgresult!, scale: 1.0, orientation: originalOrientation)
            
            imageToFilter.image = filteredImage
        }
        
    }
    
    func imageFilterTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        self.recipeImageView.image = tappedImage.image
        
        // Handles the case where a user is editing a recipe and clicks on a new filter
        // Not handling special case where user clicks on same filter as original
        // because we're not keeping track of the original filter at all
        self.newRecipeImageSelected = true
    }
    
    func startActivityIndicators() {
        self.activityIndicator.startAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func endActivityIndicators() {
        self.activityIndicator.stopAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
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
    
    func textFieldDidChange(_ textField: UITextField) {
        if textField.text != "" && textField.font?.fontName == ".SFUIText-Italic" {
            textField.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        }
        else if textField.text == "" && textField.font?.fontName != ".SFUIText-Italic" {
            textField.font = UIFont.italicSystemFont(ofSize: UIFont.systemFontSize)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.recipeNameTextField {
            self.recipeNameTextField.endEditing(true)
            self.recipeNameTextField.resignFirstResponder()
        }
        else {
            self.ingredientTextField.endEditing(true)
            self.ingredientTextField.resignFirstResponder()
        }
        return true
    }
    
    
    // MARK: - Text View Delegate Methods
    
    func textViewDidChange(_ textView: UITextView) {
        
        if textView.isEmpty() {
            if textView == self.descriptionTextView {
                self.descriptionPlaceholder.alpha = 1
            }
            else if textView == self.instructionTextView {
                self.instructionPlaceholder.alpha = 1
            }
            return
        }
        
        if textView == self.descriptionTextView {
            self.descriptionPlaceholder.alpha = 0
            self.descriptionViewHeightConstraint.constant = textView.getSizeThatFits().height
        }
        else if textView == self.instructionTextView {
            self.instructionPlaceholder.alpha = 0
            self.instructionViewHeightConstraint.constant = textView.getSizeThatFits().height
        }
        
    }
    
    // MARK: - Fusama delegate methods
    func fusumaImageSelected(_ image: UIImage, source: FusumaMode) {
        self.newRecipeImageSelected = true
        self.deleteImageButton.alpha = 1
        addImageToView(image: image)
    }
    
    func fusumaVideoCompleted(withFileURL fileURL: URL) {
        return
    }
    
    func fusumaCameraRollUnauthorized() {
        print("Camera roll unauthorized")
    }
    
    // MARK: - Table View Delegate Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.ingredientsTableView {
            return self.ingredients.count
        }
        else {
            return self.instructions.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell:UITableViewCell = UITableViewCell()
        var labelText:String = ""
        
        if tableView == self.ingredientsTableView {
            cell = self.ingredientsTableView.dequeueReusableCell(withIdentifier: "ingredientCell")!
            labelText = self.ingredients[indexPath.row]
        }
        else {
            cell = self.instructionsTableView.dequeueReusableCell(withIdentifier: "instructionCell")!
            labelText = self.instructions[indexPath.row]
        }
        
        let label:UILabel = cell.viewWithTag(1) as! UILabel
        label.text = labelText
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == self.ingredientsTableView {
            let ingredient = self.ingredients[indexPath.row]
            return self.ingredientRowHeights[ingredient]!
        }
        else {
            let instruction = self.instructions[indexPath.row]
            return self.instructionRowHeights[instruction]!
        }
    }        
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return tableView.isEditing
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        // Row has been deleted

        if tableView == self.ingredientsTableView {
            
            let ingredient = self.ingredients[indexPath.row]
            let height = self.ingredientRowHeights[ingredient]

            self.contentViewHeightConstraint.constant -= height!
            self.ingredientsTableHeightConstraint.constant -= height!
            
            // If this row has an id it means it's in the database so we
            // add it to ingredientsToDelete array and stop storing its row id
            if indexPath.row < self.ingredientRowIds.count {
                self.ingredientIdsToDelete.append(self.ingredientRowIds[indexPath.row])
                self.ingredientRowIds.remove(at: indexPath.row)
            }
            
            self.ingredients.remove(at: indexPath.row)
            self.ingredientsTableView.reloadData()
            
            if self.ingredients.count == 0 {
                if tableView.isEditing {
                    tableView.isEditing = false
                }
                self.editIngredientButton.alpha = 0
            }
        }
        else {
            
            let instruction = self.instructions[indexPath.row]
            let height = self.instructionRowHeights[instruction]
            
            self.contentViewHeightConstraint.constant -= height!
            self.instructionsTableHeightConstraint.constant -= height!
            
            // If this row has an id it means it's in the database so we
            // add it to instructionsToDelete array and stop storing its row id
            if indexPath.row < self.instructionRowIds.count {
                self.instructionIdsToDelete.append(self.instructionRowIds[indexPath.row])
                self.instructionRowIds.remove(at: indexPath.row)
            }
            
            self.instructions.remove(at: indexPath.row)
            self.instructionsTableView.reloadData()
            
            if self.instructions.count == 0 {
                if tableView.isEditing {
                    tableView.isEditing = false
                }
                self.editInstructionButton.alpha = 0
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        if tableView == self.ingredientsTableView {
            let ingredientToMove:String = self.ingredients[sourceIndexPath.row]
            self.ingredients.remove(at: sourceIndexPath.row)
            self.ingredients.insert(ingredientToMove, at: destinationIndexPath.row)
        }
        else {
            let instructionToMove:String = self.instructions[sourceIndexPath.row]
            self.instructions.remove(at: sourceIndexPath.row)
            self.instructions.insert(instructionToMove, at: destinationIndexPath.row)
        }

    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor.clear
    }

}
