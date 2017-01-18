//
//  LoginViewController.swift
//  Recipes
//
//  Created by Tushar Verma on 1/16/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    let saveFBAccountUrl:String = "http://iosrecipes.com/saveFBAccount.php"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let loginButton:FBSDKLoginButton = FBSDKLoginButton()
        view.addSubview(loginButton)
        loginButton.frame = CGRect(x: 16, y: 50, width: view.frame.width - 32, height: 50)
        
        loginButton.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Leave this in case we want to start saving fb data
    func saveFBAccount(userId:String, fbProfileName:String) {
        
        // Create json object
        var json:[String:String] = [String:String]()
        json["fb_user_id"] = userId
        json["fb_profile_name"] = fbProfileName
        
        let data:Data = try! JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        // Create url object
        let url:URL = URL(string: self.saveFBAccountUrl)!
       
        // Create and initialize request
        var request:URLRequest = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.httpBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let task:URLSessionDataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("There was an error running the save fb account task")
                print((error?.localizedDescription)!)
                return
            }
            
            do {
                // Parse response data into json
                let json:NSDictionary = try JSONSerialization.jsonObject(with: data!, options: []) as! NSDictionary
            
                // Check status
                if String(describing: json["status"]).lowercased().range(of: "error") != nil {
                    print("Error saving fb account: " + String(describing: json["message"]))
                    return
                }
            }
            catch let e as NSError {
                print("Error: couldn't convert response to valid json, " + e.localizedDescription)
                return
            }
            
            // Set current user fields
            CurrentUser.userId = userId
            CurrentUser.userName = fbProfileName
            
            // Segue to main view
            let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let navigationVC:UIViewController = storyBoard.instantiateViewController(withIdentifier: "navigationController")
            
            self.present(navigationVC, animated: true, completion: nil)
        }
        
        task.resume()
    }
    
    // MARK: - Login Button Delegate Methods
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        if error != nil {
            print(error)
            return
        }
        
        print("logged in to fb successfully")
        
        let accessToken:FBSDKAccessToken = FBSDKAccessToken.current()
        
        let request:FBSDKGraphRequest? = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"name"], tokenString: accessToken.tokenString, version: nil, httpMethod: "GET")
        
        request?.start(completionHandler: { (_, result, error) in
            
            if(error != nil) {
                print("There was an error logging into fb: \(error)")
            }
            
            if let unwrappedResult = result {
                let json:[String:String] = unwrappedResult as! [String:String]
                
                // Set current user fields
                CurrentUser.userId = json["id"]!
                CurrentUser.userName = json["name"]!
                
                // Segue to main view
                let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let navigationVC:UIViewController = storyBoard.instantiateViewController(withIdentifier: "navigationController")
                
                self.present(navigationVC, animated: true, completion: nil)
            }

        })
        
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("logged out and clearing current user")
        CurrentUser.clearCurrentUser()
    }
    

}
