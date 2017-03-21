//
//  SettingsTableViewController.swift
//  Recipes
//
//  Created by Tushar Verma on 3/20/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit
import InAppSettingsKit
import FBSDKLoginKit

class SettingsTableViewController: IASKAppSettingsViewController, IASKSettingsDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func synchronizeSettings() {
        
    }
    
    override func dismiss(_ sender: Any!) {
        
    }
    
    override func setHiddenKeys(_ hiddenKeys: Set<AnyHashable>!, animated: Bool) {
        
    }
    
    // MARK: - IASK Settings Delegate Methods
    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController!) {
        
    }
    
    func tableView(_ tableView: UITableView!, heightFor specifier: IASKSpecifier!) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView!, cellFor specifier: IASKSpecifier!) -> UITableViewCell! {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "logoutCell")!
        
        let logoutButton:UIButton = cell.viewWithTag(1) as! UIButton
        logoutButton.addTarget(self, action: #selector(self.logoutTapped(_:)), for: UIControlEvents.touchUpInside)
        
        return cell
        
    }
    
    @IBAction func logoutTapped(_ sender: UIBarButtonItem) {
        // Create a new alert controller
        let actionSheet:UIAlertController = UIAlertController(title: nil, message: "Are you sure?", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        // Add an Alert Action
        let logoutAction:UIAlertAction = UIAlertAction(title: "Logout", style: UIAlertActionStyle.destructive,
            handler: { (alertAction:UIAlertAction!) in
                
            NSLog("logging out")
            CurrentUser.clearCurrentUser()
            let loginManager = FBSDKLoginManager()
            loginManager.logOut() // this is an instance function
            self.performSegue(withIdentifier: "toLogin", sender: self)
        })
        
        // Add another action
        let cancelAction:UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {
            (alertAction:UIAlertAction!) in
            NSLog("canceled logout")
        })
        
        
        actionSheet.addAction(logoutAction)
        actionSheet.addAction(cancelAction)
        self.present(actionSheet, animated: true, completion: nil)
    }

}









