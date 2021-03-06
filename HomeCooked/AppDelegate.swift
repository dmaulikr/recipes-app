//
//  AppDelegate.swift
//  Recipes
//
//  Created by Tushar Verma on 11/10/16.
//  Copyright © 2016 Tushar Verma. All rights reserved.
//

import UIKit
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let fileManagerUtil = RecipesFileManagerUtil()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Create file on device for saving recipes if it hasn't already been created
        let filemgr = self.fileManagerUtil.getDefaultFileManager()
        let directoryHome = self.fileManagerUtil.getDocumentsDirectory().path
        let dataDir = directoryHome + "/data"
        let recipesFile = dataDir + "/recipes"
        
        if !filemgr.fileExists(atPath: dataDir) {
            print("creating data directory")
            fileManagerUtil.createDirectory(path: dataDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        if !filemgr.fileExists(atPath: recipesFile) {
            print("creating recipes file")
            filemgr.createFile(atPath: recipesFile, contents: nil, attributes: nil)
        }
        
        // Cache the file system urls
        UserDefaults.standard.set(dataDir, forKey: Config.UserDefaultsKey.mainDirectoryFilePathKey)
        UserDefaults.standard.set(recipesFile, forKey: Config.UserDefaultsKey.recipesFilePathKey)
        
        // TODO: Only need initialize the key for testing because we're skipping the login
        UserDefaults.standard.set("", forKey: Config.UserDefaultsKey.currentUserIdKey)
        UserDefaults.standard.set("", forKey: Config.UserDefaultsKey.currentUserNameKey)
        
        // Facebook Delegate integration
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        return true
    }
    
    // For Facebook integration
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let handled:Bool = FBSDKApplicationDelegate.sharedInstance().application(
            app,
            open: url,
            sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String!,
            annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        
        return handled
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

