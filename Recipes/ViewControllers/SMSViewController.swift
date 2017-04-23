//
//  SMSViewController.swift
//  Recipes
//
//  Created by Tushar Verma on 4/22/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit
import InAppSettingsKit

class SMSViewController: UIViewController, MFMessageComposeViewControllerDelegate {

    var smsComposer:MFMessageComposeViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initWithFile(_ sender: NSString, specifier: IASKSpecifier) {
        // Check if this device can send a message
        if MFMessageComposeViewController.canSendText() {
            
            self.smsComposer = MFMessageComposeViewController()
            
            self.smsComposer?.messageComposeDelegate = self
            
            self.smsComposer?.body = "Hey! Go download HomeCooked! It lets you create, manage, and update any home-made recipes so you can remember all the awesome meals you've made! Just search HomeCooked in the app store to find it."
            
            self.present(self.smsComposer!, animated: true, completion: nil)
        }
        else {
            NSLog("Device can't send text")
        }
    }
    
    // MARK: - SMS View Delegates
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        
        switch(result.rawValue) {
            
        case MessageComposeResult.sent.rawValue:
            NSLog("Message sent")
        case MessageComposeResult.cancelled.rawValue:
            NSLog("Message cancelled")
        case MessageComposeResult.failed.rawValue:
            NSLog("Message failed")
        default:
            NSLog("Something else")
        }
        
        self.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
    }
}
