//
//  AlertControllerService.swift
//  Recipes
//
//  Created by Tushar Verma on 3/24/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit

class AlertControllerService: NSObject {
    
    func displayErrorAlert(actionToRetry: @escaping() -> Void) -> UIAlertController {
        return displayErrorAlert(message: "Oops, something went wrong!", actionToRetry: {
            actionToRetry()
        })
        
    }

    func displayErrorAlert(message:String, actionToRetry: @escaping() -> Void) -> UIAlertController {
        
        let alert:UIAlertController = UIAlertController(title: nil, message: "Oops, something went wrong!", preferredStyle: UIAlertControllerStyle.alert)
        
        let retryAction:UIAlertAction = UIAlertAction(title: "Retry", style: UIAlertActionStyle.cancel,
            handler: { (alertAction:UIAlertAction!) in
            print("retry button clicked")
            actionToRetry()
        })
        
        let dismissAction:UIAlertAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,
            handler: { (alertAction:UIAlertAction!) in
            
            print("dismiss button clicked")
        })
        
        alert.addAction(retryAction)
        alert.addAction(dismissAction)
        return alert
        
    }


}
