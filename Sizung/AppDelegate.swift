//
//  AppDelegate.swift
//  Sizung
//
//  Created by Markus Klepp on 02/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import Alamofire
import SwiftKeychainWrapper
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    
    Fabric.with([Crashlytics.self])
    
    let authToken = KeychainWrapper.stringForKey(Configuration.Settings.AUTH_TOKEN)
    
    let token = AuthToken(data: authToken)
    token.validate()
      .onSuccess { _ in
        self.loadInitialViewController()
      }.onFailure { error in
        self.showLogin()
    }

    return true
  }
  
  func loadInitialViewController() {
    guard KeychainWrapper.stringForKey(Configuration.Settings.SELECTED_ORGANIZATION) != nil else {
      let organizationViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("OrganizationsTableViewController")
      self.window?.rootViewController?.presentViewController(organizationViewController, animated: false, completion: nil)
      return
    }
  }
  
  func showLogin(){
    let modalViewController = LoginViewController(nibName: "Login", bundle: nil)
    modalViewController.modalPresentationStyle = .OverCurrentContext
    self.window?.rootViewController?.presentViewController(modalViewController, animated: true, completion: nil)
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

