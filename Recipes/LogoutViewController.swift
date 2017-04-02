//
//  LogoutViewController.swift
//  Recipes
//
//  Created by Tushar Verma on 3/17/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class LogoutViewController: UIViewController, FBSDKLoginButtonDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let logoutButton:FBSDKLoginButton = FBSDKLoginButton()
        view.addSubview(logoutButton)
        
        let screenWidth:CGFloat = view.frame.width
        let screenHeight:CGFloat = view.frame.height
        
        logoutButton.frame = CGRect(x: 16, y: (screenHeight / 2) + 30, width: screenWidth - 32, height: 50)
        
        logoutButton.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Login Button Delegate Methods
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
//        if error != nil {
//            print(error)
//            return
//        }
//        
//        print("logged in to fb successfully")
//        
//        let accessToken:FBSDKAccessToken = FBSDKAccessToken.current()
//        
//        let request:FBSDKGraphRequest? = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"name"], tokenString: accessToken.tokenString, version: nil, httpMethod: "GET")
//        

        
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("logged out and clearing current user")
//        CurrentUser.clearCurrentUser()
    }

}
