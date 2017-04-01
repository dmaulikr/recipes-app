//
//  DataTaskUtil.swift
//  Recipes
//
//  Created by Tushar Verma on 3/24/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit

class DataTaskUtil: NSObject {
    
    func getJson(data: Data) -> NSDictionary? {
        do {
            let json:NSDictionary = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
            return json
        }
        catch let e as NSError {
            print("Error: couldn't convert response to valid json, " + e.localizedDescription)
            return nil
        }
    }
    
    func isValidJson(json: NSDictionary?) -> Bool {
        if json == nil || !JSONSerialization.isValidJSONObject(json!) {
            return false
        }
                        
        if String(describing: json?["status"]).lowercased().range(of: "error") != nil {
            return false
        }
        return true
    }
    
    func isValidResponse(response:URLResponse?, error:Error?) -> Bool {
        
        if error != nil {
            print("There was an error loading the url, " + (error?.localizedDescription)!)
            return false
        }
        
        let httpResponse:HTTPURLResponse? = response as! HTTPURLResponse?
        if httpResponse?.statusCode != 200 {
            print("Error loading url, status code of " + String(httpResponse!.statusCode))
            return false
        }
        
        return true
    }

}
