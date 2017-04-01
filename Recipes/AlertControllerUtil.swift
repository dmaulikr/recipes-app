//
//  AlertControllerUtil.swift
//  Recipes
//
//  Created by Tushar Verma on 3/24/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit

class AlertControllerUtil: NSObject {
    
    func displayAlertMessage(presentOn:UIViewController, message:String) {
        let alert:UIAlertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let dismissAction:UIAlertAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(dismissAction)
        presentOn.present(alert, animated: true, completion: nil)
    }
    
    func displayErrorAlert(presentOn:UIViewController, actionToRetry: @escaping() -> Void) {
        let alert = getAlert(message: "Oops, something went wrong!", actionToRetry: {
            actionToRetry()
        })
        presentOn.present(alert, animated: true, completion: nil)
    }

    func displayErrorAlert(presentOn:UIViewController, message:String, actionToRetry: @escaping() -> Void) {
        let alert = getAlert(message: message, actionToRetry: {
            actionToRetry()
        })
        presentOn.present(alert, animated: true, completion: nil)
    }
    
    private func getAlert(message:String, actionToRetry: @escaping() -> Void) -> UIAlertController {
        
        let alert:UIAlertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let retryAction:UIAlertAction = UIAlertAction(title: "Retry", style: UIAlertActionStyle.cancel,
                                                      handler: { (alertAction:UIAlertAction!) in
            print("retry button clicked")
            actionToRetry()
        })
        
        let dismissAction:UIAlertAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil)
        
        alert.addAction(retryAction)
        alert.addAction(dismissAction)
        return alert

    }

}
