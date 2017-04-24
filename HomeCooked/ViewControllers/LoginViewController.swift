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
    
    // Outlets
    @IBOutlet weak var sloganLabel: UILabel!
    
    let alertControllerUtil:AlertControllerUtil = AlertControllerUtil()
    let dataTaskUtil:DataTaskUtil = DataTaskUtil()
    let margin:CGFloat = 30
    
    // Views to add
    var loginButton:FBSDKLoginButton = FBSDKLoginButton()
    var activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView()
    
    // Needed because viewDidLayoutSubviews() is called multiple times
    var needToDisplayMainView:Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loginButton.delegate = self
        
        if FBSDKAccessToken.current() == nil {
            print("not logged in")
        
            let screenWidth:CGFloat = view.frame.width
            let screenHeight:CGFloat = view.frame.height
            
            // The slogan label is in the middle of the screen, so we put the login button right below
            self.loginButton.frame = CGRect(x: self.margin, y: (screenHeight / 2) + 30, width: screenWidth - (2 * self.margin), height: 50)
            view.addSubview(loginButton)
        }
    }
    
    override func viewDidLayoutSubviews() {
        if FBSDKAccessToken.current() != nil && self.needToDisplayMainView {
            print("already logged in")
            self.getFBInfo(accessToken: FBSDKAccessToken.current(), completionHandler: { (fbUserId, fbProfileName) in
                UserDefaults.standard.set(fbUserId, forKey: Config.UserDefaultsKey.currentUserIdKey)
                UserDefaults.standard.set(fbProfileName, forKey: Config.UserDefaultsKey.currentUserNameKey)
                
                self.performSegue(withIdentifier: "toMainView", sender: self)
                self.needToDisplayMainView = false
            })
        }
    }
    
    // Return fbUserId, fbProfileName
    func getFBInfo(accessToken:FBSDKAccessToken, completionHandler: @escaping (String, String) -> Swift.Void) {
        let request:FBSDKGraphRequest? = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"name"], tokenString: accessToken.tokenString, version: nil, httpMethod: "GET")
        
        request?.start(completionHandler: { (_, result, error) in
            let json:[String:String] = result as! [String:String]
            completionHandler(json["id"]!, json["name"]!)
        })
    }
    
    func saveFBAccount(userId:String, fbProfileName:String, completionHandler: @escaping (Bool) -> Swift.Void) {
        
        print("Saving fb account \(userId) \(fbProfileName)")
        
        var json:[String:String] = [String:String]()
        json["fb_user_id"] = userId
        json["fb_profile_name"] = fbProfileName
        
        let url = Config.sharedInstance.getAPIEndpoint(endpoint: .saveFBAccount)
        var headers = [String:String]()
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        
        
        self.dataTaskUtil.executeHttpRequest(url: url, httpMethod: .post, headerFieldValuePairs: headers, jsonPayload: json as NSDictionary) { (data, response, error) in
            
            if !self.dataTaskUtil.isValidResponse(response: response, error: error) {
                completionHandler(false)
                return
            }
                
            let json:NSDictionary? = self.dataTaskUtil.getJson(data: data!)
            if !self.dataTaskUtil.isValidJson(json: json) {
                completionHandler(false)
                return
            }
                
            print("fb data saved successfully")
            completionHandler(true)
        }
        
    }

    
    // MARK: - Login Button Delegate Methods
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        if error != nil {
            print(error)
            self.alertControllerUtil.displayAlertMessage(presentOn: self, message: "Oops, there was an issue logging in! Please try again")
            return
        }
        
        // We don't want the user to be logged in from viewDidLayoutSubviews()
        self.needToDisplayMainView = false
        
        print("logged in to fb successfully")
        let buttonText = NSAttributedString(string: "Logging in ...")
        self.loginButton.setAttributedTitle(buttonText, for: .normal)
        
        let x = self.loginButton.frame.origin.x + self.loginButton.frame.width - 50
        self.activityIndicator.frame = CGRect(x: x, y: self.loginButton.frame.origin.y, width: 50, height: 50)
        self.activityIndicator.startAnimating()
        view.addSubview(self.activityIndicator)
        
        self.getFBInfo(accessToken: FBSDKAccessToken.current(), completionHandler: { (fbUserId, fbProfileName) in
            self.saveFBAccount(userId: fbUserId, fbProfileName: fbProfileName, completionHandler: { (success) in
                // Although we normally want to check for success, and retry if it's false, saving this data isn't necessary
                // for the user to actually use the app. 
                // So, in case there is some issue, we ignore the success flag and just log the user in
                DispatchQueue.main.async {
                    UserDefaults.standard.set(fbUserId, forKey: Config.UserDefaultsKey.currentUserIdKey)
                    UserDefaults.standard.set(fbProfileName, forKey: Config.UserDefaultsKey.currentUserNameKey)
                    self.performSegue(withIdentifier: "toMainView", sender: self)
                }
            })
        })
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        // Don't need to handle logout from this view
    }
}
