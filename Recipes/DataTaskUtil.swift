//
//  DataTaskUtil.swift
//  Recipes
//
//  Created by Tushar Verma on 3/24/17.
//  Copyright © 2017 Tushar Verma. All rights reserved.
//

import UIKit

class DataTaskUtil: NSObject {
    
    enum HttpMethod:String {
        case post = "POST"
        case get = "GET"
    }
    
    func executeHttpRequest(url:String, httpMethod:HttpMethod, headerFieldValuePairs:[String:String], jsonPayload:NSDictionary?,
                            completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) {
        var data:Data?
        do {
            data = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted)
        }
        catch let e as NSError {
            print("Error: couldn't convert recipe json to data object, " + e.localizedDescription)
            completionHandler(nil, nil, e)
            return
        }
        
        let request:URLRequest = initializeUrlRequest(url: url, httpMethod: httpMethod,
                                                      headerFieldValuePairs: headerFieldValuePairs, httpBody: data)
        let task:URLSessionDataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            completionHandler(data, response, error)
        }
        task.resume()
    }
    
    func executeHttpRequest(url:String, httpMethod:HttpMethod, headerFieldValuePairs:[String:String], httpBody:Data?,
                            completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) {
        let request:URLRequest = initializeUrlRequest(url: url, httpMethod: httpMethod, headerFieldValuePairs: headerFieldValuePairs, httpBody: httpBody)
        let task:URLSessionDataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            completionHandler(data, response, error)
        }
        task.resume()
    }
    
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
    
    private func initializeUrlRequest(url:String, httpMethod:HttpMethod, headerFieldValuePairs:[String:String],
                                      httpBody:Data?) -> URLRequest {
        let requestUrl:URL = URL(string: url)!
        var request:URLRequest = URLRequest(url: requestUrl)
        
        request.httpMethod = httpMethod.rawValue
        for (field, value) in headerFieldValuePairs {
            request.addValue(value, forHTTPHeaderField: field)
        }
        
        if httpBody != nil {
            request.httpBody = httpBody
        }
        
        return request
    }

}
