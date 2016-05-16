//
//  AppDelegate.swift
//  Sizung
//
//  Created by Markus Klepp on 02/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import Alamofire
import Spine

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    
    let token = KeychainWrapper().myObjectForKey(kSecValueData)
    
    if (token == nil) {
      let loginViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("LoginViewController")
      self.window!.rootViewController = loginViewController;
    } else {
      
      self.initSpine(token as! String)
    }
    return true
  }
  
  func initSpine(token: String) {
    let baseURL = NSURL(string: Configuration.APIEndpoint())
    let spine = Spine(baseURL: baseURL!)
    
    (spine.networkClient as! HTTPClient).setHeader("Authorization", to: "Bearer \(token)")
    (spine.networkClient as! HTTPClient).setHeader("Accept", to: "application/json")
    
    spine.registerResource(Organization)
    
    Spine.setLogLevel(.Debug, forDomain: .Spine)
    Spine.setLogLevel(.Debug, forDomain: .Networking)
    Spine.setLogLevel(.Debug, forDomain: .Serializing)
    
    spine.findAll(Organization)
      
      .onSuccess { (resources, meta, jsonapi) in
        print("Fetched resource collection: \(resources)")
      }
      .onFailure { (error) in
        print(error)
        self.window?.rootViewController?.performSegueWithIdentifier("showLogin", sender: nil)
    }
  }
  
  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }
  
  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }
  
  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }
  
  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }
  
  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  
}

