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
    @IBOutlet weak var instructionTextField: UITextField!
    @IBOutlet weak var ingredientsTableView: UITableView!
    @IBOutlet weak var instructionsTableView: UITableView!
    
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var recipeImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var recipeFiltersHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ingredientsTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var instructionsTableHeightConstraint: NSLayoutConstraint!
    
    // Constants
    let saveRecipeUrl:String = "http://iosrecipes.com/saveRecipe.php"
    let saveRecipeImageUrl:String = "http://iosrecipes.com/saveRecipeImage.php"
    let editRecipeUrl:String = "http://iosrecipes.com/editRecipe.php"
    let updateRecipeUrl:String = "http://iosrecipes.com/updateRecipe.php"
    let defaultTableRowHeight:CGFloat = 50
    let textViewPlaceholder:String = "Add description"
    
    // Member variables to be set before presenting view if editing a recipe
    var editingRecipe:Bool = false
    var recipeToEdit:Recipe?
    // array of table row to its associated id (ids are needed when users edit ingredients/instructions)
    var ingredientRowIds:[Int] = [Int]()
    var instructionRowIds:[Int] = [Int]()
    
    // Misc
    var fusama:FusumaViewController = FusumaViewController() // Image Picker Controller
    var ingredients:[String] = [String]()
    var instructions:[String] = [String]()
    
    var ingredientIdsToDelete:[Int] = [Int]()
    var instructionIdsToDelete:[Int] = [Int]()
    
    var activeTextField:UITextField?
    
    let filtersToIntensity:[String:Float?] = [
        "CIPhotoEffectChrome" : nil,
        "CIPhotoEffectFade" : nil, // only takes image
        "CIPhotoEffectInstant" : nil, // only image
        "CIPhotoEffectProcess": nil, // image
        "CIPhotoEffectTonal": nil, // image
        "CIPhotoEffectTransfer": nil, // image
        "CISepiaTone": 0.5,
        "CIVignette" : 1
    ]

    
    enum TextFieldTags:Int {
        case RECIPE = 1
        case INGREDIENT = 2
        case INSTRUCTION = 3
        case ALL = 4
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Set table view backgrounds to clear
        self.ingredientsTableView.backgroundColor = UIColor.clear
        self.instructionsTableView.backgroundColor = UIColor.clear

        // Style description text view
        let borderColor:UIColor = DefaultColors.greyBorderColor
    
        descriptionTextView.layer.borderWidth = 0.5
        descriptionTextView.layer.borderColor = borderColor.cgColor
        descriptionTextView.layer.cornerRadius = 5.0
        descriptionTextView.text = self.textViewPlaceholder
        descriptionTextView.font = UIFont.italicSystemFont(ofSize: UIFont.systemFontSize)
        descriptionTextView.textColor = UIColor.lightGray
        
        // Set properties of fusama image picker controller
        fusama.hasVideo = false
        
        // Assign self to delegates and datasources
        fusama.delegate = self

        recipeNameTextField.delegate = self
        ingredientTextField.delegate = self
        instructionTextField.delegate = self
        descriptionTextView.delegate = self
        ingredientsTableView.delegate = self
        instructionsTableView.delegate = self
        
        ingredientsTableView.dataSource = self
        instructionsTableView.dataSource = self
        
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
    
    override func viewDidLayoutSubviews() {
        // Check if the instruction view has been loaded and then set content height
        // to allow the scrollview to scroll
        if self.instructionsTableView.frame.origin.y > 0 {
            self.contentViewHeightConstraint.constant = self.instructionsTableView.frame.maxY + 100
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
        let recipeIngredients:[String] = (self.recipeToEdit?.ingredients)!
        for i in 0 ..< recipeIngredients.count {
        
            // Add to ingredients array
            let ingredient:String = recipeIngredients[i]
            self.ingredients.append(ingredient)
            
            // Add to row ids array
            self.ingredientRowIds.append((self.recipeToEdit?.ingredientToIdMap[ingredient])!)
            
            // Adjust height constraints
            self.ingredientsTableHeightConstraint.constant += self.defaultTableRowHeight
            self.contentViewHeightConstraint.constant += self.defaultTableRowHeight
        }
        
        // Add each instruction to the table
        let recipeInstructions:[String] = (self.recipeToEdit?.instructions)!
        for i in 0 ..< recipeInstructions.count {
            
            // Add to instructions array
            let instruction:String = recipeInstructions[i]
            self.instructions.append(instruction)
            
            // Add to row ids array
            self.instructionRowIds
                    .append((self.recipeToEdit?.instructionToIdMap[instruction])!)
            
            // Adjust height constraints
            self.instructionsTableHeightConstraint.constant += self.defaultTableRowHeight
            self.contentViewHeightConstraint.constant += self.defaultTableRowHeight
        }
        
        self.ingredientsTableView.reloadData()
        self.instructionsTableView.reloadData()

    }
    
    @IBAction func addImageClicked(_ sender: UIButton) {
        
        // Check if the device has a camera
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            self.present(self.fusama, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func addIngredientClicked(_ sender: UIButton) {
        
        if self.ingredientTextField.text == "" {
            return
        }

        self.ingredientsTableHeightConstraint.constant += self.defaultTableRowHeight
        self.contentViewHeightConstraint.constant += self.defaultTableRowHeight
        
        self.ingredients.append(self.ingredientTextField.text!)
        self.ingredientsTableView.reloadData()
        
    }
    
    
    @IBAction func editIngredientClicked(_ sender: UIButton) {
        self.ingredientsTableView.isEditing = !self.ingredientsTableView.isEditing
    }
    
    
    @IBAction func addInstructionClicked(_ sender: UIButton) {
        
        if self.instructionTextField.text == "" {
            return
        }
        
        self.instructionsTableHeightConstraint.constant += self.defaultTableRowHeight
        self.contentViewHeightConstraint.constant += self.defaultTableRowHeight
        
        self.instructions.append(self.instructionTextField.text!)
        self.instructionsTableView.reloadData()
        
    }
    
    
    @IBAction func editInstructionClicked(_ sender: UIButton) {
        self.instructionsTableView.isEditing = !self.instructionsTableView.isEditing
    }
    
    
    @IBAction func cancelRecipeClicked(_ sender: UIBarButtonItem) {
        self.presentNavigationController()
    }
    
    
    @IBAction func saveRecipeClicked(_ sender: UIBarButtonItem) {
        
        self.activityIndicator.startAnimating()
        
        // If no image, just save the recipe data
        if self.recipeImageView == nil || self.recipeImageView.image == nil {
            self.saveRecipeData(imageId: nil)
            return
        }
        
        // Otherwise, we want to save the image and then save the recipe data on success
        
        // Create request object
        let url:URL = URL(string: self.saveRecipeImageUrl)!
        var request:URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Create and initialize the body
        let body:NSMutableData = NSMutableData()
        
        let imageData:Data = UIImageJPEGRepresentation(self.recipeImageView.image!, 1)!
        let boundary:String = "Boundary-\(NSUUID().uuidString)"
        let filePathKey:String = "file"
        let filename:String = "tmp.jpg" // the script will create the actual file name
        let mimetype:String = "image/jpg"
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        body.appendString(string: "--\(boundary)\r\n")
        body.appendString(string: "Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n")
        body.appendString(string: "Content-Type: \(mimetype)\r\n\r\n")
        body.append(imageData)
        body.appendString(string: "\r\n")
        body.appendString(string: "--\(boundary)--\r\n")
        
        request.httpBody = body as Data
        
        let saveImageTask:URLSessionDataTask = URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            
            // Log status result of task
            if error != nil {
                print("There was an error running the task to save the image")
                print((error?.localizedDescription)!)
                return
            }
            
            // Create variable to store image blob id returned from script
            var imageId:Int?
            do {
                // Parse response data into json
                let json:NSDictionary = try JSONSerialization.jsonObject(with: data!, options: []) as! NSDictionary
                
                // Check status
                if String(describing: json["status"]).lowercased().range(of: "error") != nil {
                    print("Error saving image: " + String(describing: json["message"]))
                    return
                }
                
                imageId = json["image_id"] as? Int
            }
            catch let e as NSError {
                print("Error: couldn't convert response to valid json, " + e.localizedDescription)
                return
            }
            
            // Go back to ViewController
            DispatchQueue.main.async {
                self.saveRecipeData(imageId: imageId)
            }
            
        })
        
        saveImageTask.resume()
    }
    
    func saveRecipeData(imageId:Int?) {
        
        // Create recipe object to save
        let recipe:Recipe = Recipe()
        
        recipe.name = recipeNameTextField.text!
        
        // Save recipe description if it's not the placeholder
        if descriptionTextView.text != self.textViewPlaceholder {
            recipe.recipeDescription = descriptionTextView.text
        }
        
        // Loop through each ingredient
        for i in 0 ..< self.ingredients.count {
            
            let ingredient:String = self.ingredients[i]
            recipe.ingredients.append(ingredient)
            
            // If the ingredient row has an id, add it to ingredientToId map
            if i < self.ingredientRowIds.count {
                recipe.ingredientToIdMap[ingredient] = self.ingredientRowIds[i]
            }
        }
        
        // Loop through each instruction
        for i in 0 ..< self.instructions.count {
            
            let instruction:String = self.instructions[i]
            recipe.instructions.append(instruction)
            
            // If the instruction row has an id, add it to the instructionToId map
            if i < self.instructionRowIds.count {
                recipe.instructionToIdMap[instruction] = self.instructionRowIds[i]
            }
            
        }
        
        // Save the recipeId if this is recipe is being edited
        if self.editingRecipe && self.recipeToEdit != nil {
            recipe.recipeId = (self.recipeToEdit?.recipeId)!
        }
        
        // Save the recipe as a json data object
        var data:Data?
        do {
            
            var json:[String:AnyObject] = [
                "fb_user_id" : CurrentUser.userId as AnyObject,
                "recipe_id" : recipe.recipeId as AnyObject,
                "name" : recipe.name as AnyObject,
                "description" : recipe.recipeDescription as AnyObject,
                "ingredients" : recipe.ingredients as AnyObject,
                "instructions" : recipe.instructions as AnyObject,
                "ingredient_to_id_map" : recipe.ingredientToIdMap as AnyObject,
                "instruction_to_id_map" : recipe.instructionToIdMap as AnyObject,
                "image_id" : "" as AnyObject,
                "ingredients_to_delete" : self.ingredientIdsToDelete as AnyObject,
                "instructions_to_delete" : self.instructionIdsToDelete as AnyObject
            ]
            
            if imageId != nil {
                json["image_id"] = imageId! as AnyObject
            }
            
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
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Create task to save or update the recipe
        let session:URLSession = URLSession.shared
        let saveRecipeTask:URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            
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
                self.activityIndicator.stopAnimating()
                self.presentNavigationController()
            }
            
        })
        
        
        // Run the task
        saveRecipeTask.resume()
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
    
    func createFilters(imageToFilter:UIImageView) {
        
        self.recipeFiltersHeightConstraint.constant = UIScreen.main.bounds.height / 3
            
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
                
                // TODO: Change logic so we don't hardcode indeces
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
            let filteredImage = UIImage(cgImage: cgimgresult!)
            imageToFilter.image = filteredImage
        }
        
    }
    
    
    func imageFilterTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        self.recipeImageView.image = tappedImage.image
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
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == self.textViewPlaceholder {
            textView.text = nil
            textView.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = self.textViewPlaceholder
            textView.font = UIFont.italicSystemFont(ofSize: UIFont.systemFontSize)
            textView.textColor = UIColor.lightGray
        }
    }
    
    // MARK: - Fusama delegate methods
    func fusumaImageSelected(_ image: UIImage, source: FusumaMode) {
        print("Image selected")
        self.recipeImageView.image = image
        self.recipeImageHeightConstraint.constant = UIScreen.main.bounds.height / 2
        self.contentViewHeightConstraint.constant += self.recipeImageHeightConstraint.constant
        createFilters(imageToFilter: self.recipeImageView)
    }
    
    func fusumaVideoCompleted(withFileURL fileURL: URL) {
        return
    }
    
    // When camera roll is not authorized, this method is called.
    func fusumaCameraRollUnauthorized() {
        print("Camera roll unauthorized")
    }

    // MARK: - Image Picker Delegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        self.recipeImageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        self.recipeImageHeightConstraint.constant = UIScreen.main.bounds.height / 2
        self.contentViewHeightConstraint.constant += self.recipeImageHeightConstraint.constant
        
        // To dismiss the image picker
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
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
        return self.defaultTableRowHeight
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        // Adjust height of content
        self.contentViewHeightConstraint.constant -= self.defaultTableRowHeight

        if tableView == self.ingredientsTableView {
            // Adjust table height
            self.ingredientsTableHeightConstraint.constant -= self.defaultTableRowHeight
            
            // If this row has an id it means it's in the database so we
            // add it to ingredientsToDelete array and stop storing its row id
            if indexPath.row < self.ingredientRowIds.count {
                self.ingredientIdsToDelete.append(self.ingredientRowIds[indexPath.row])
                self.ingredientRowIds.remove(at: indexPath.row)
            }
            
            // Remove from table and reload
            self.ingredients.remove(at: indexPath.row)
            self.ingredientsTableView.reloadData()
        }
        else {
            // Adjust table height
            self.instructionsTableHeightConstraint.constant -= self.defaultTableRowHeight
            
            // If this row has an id it means it's in the database so we
            // add it to instructionsToDelete array and stop storing its row id
            if indexPath.row < self.instructionRowIds.count {
                self.instructionIdsToDelete.append(self.instructionRowIds[indexPath.row])
                self.instructionRowIds.remove(at: indexPath.row)
            }
            
            // Remove from table and reload
            self.instructions.remove(at: indexPath.row)
            self.instructionsTableView.reloadData()
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
