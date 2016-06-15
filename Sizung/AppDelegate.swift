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
class AppDelegate: UIResponder, UIApplicationDelegate, LoginDelegate {
  
  var window: UIWindow?
  
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    
    self.checkSettings()
    
    #if RELEASE_VERSION
      Fabric.with([Crashlytics.self])
    #endif
    
    self.initTheme()
    
    self.registerNotifications()
    
    if let authToken = KeychainWrapper.stringForKey(Configuration.Settings.AUTH_TOKEN) {
      let token = AuthToken(data: authToken)
      token.validate()
        .onSuccess { _ in
          self.loadInitialViewController()
        }.onFailure { error in
          self.showLogin()
      }
    } else {
      self.showLogin()
    }
    
    return true
  }
  
  func checkSettings(){
    if NSUserDefaults.standardUserDefaults().boolForKey("reset_on_launch") {
      KeychainWrapper.removeObjectForKey(Configuration.Settings.AUTH_TOKEN)
      KeychainWrapper.removeObjectForKey(Configuration.Settings.SELECTED_ORGANIZATION)
      
      // Reset user defaults
      let appDomain = NSBundle.mainBundle().bundleIdentifier!
      NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
    }
  }
  
  func initTheme(){
    UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
  }
  
  func registerNotifications(){
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.showLogin), name: Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
  }
  
  func loadInitialViewController() {
    
    if let selectedOrganization = KeychainWrapper.stringForKey(Configuration.Settings.SELECTED_ORGANIZATION) {
      StorageManager.sharedInstance.updateOrganization(selectedOrganization)
    } else {
      let organizationViewController = R.storyboard.organizations.initialViewController()!
      self.window?.rootViewController?.showViewController(organizationViewController, sender: nil)
    }
  }
  
  func showLogin(){
    let loginViewController = R.storyboard.login.initialViewController()!
    loginViewController.loginDelegate = self
    loginViewController.modalPresentationStyle = .OverCurrentContext
    loginViewController.modalTransitionStyle = .CoverVertical
    
    self.window?.rootViewController = loginViewController
  }
  
  func loginSuccess(loginViewController: LoginViewController) {
    loginViewController.dismissViewControllerAnimated(true, completion: nil)
    self.window?.rootViewController = R.storyboard.main.initialViewController()
    self.loadInitialViewController()
  }
  
  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }
  
  func applicationDidEnterBackground(application: UIApplication) {
    print("applicationDidEnterBackground")
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }
  
  func applicationWillEnterForeground(application: UIApplication) {
    print("applicationWillEnterForeground")
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }
  
  func applicationDidBecomeActive(application: UIApplication) {
  
    //ensure websocket connection is open
    if let websocket = StorageManager.sharedInstance.websocket {
      if !websocket.client.connected {
        print("websocket not connected - reconnecting")
        initWebsocketConnection()
      }
    } else {
      print("websocket not initialized - connecting")
      initWebsocketConnection()
    }
  }
  
  func initWebsocketConnection(){
    if let authToken = KeychainWrapper.stringForKey(Configuration.Settings.AUTH_TOKEN) {
      StorageManager.sharedInstance.websocket = Websocket(authToken: authToken)
    }
  }
  
  func applicationWillTerminate(application: UIApplication) {
    print("applicationWillTerminate")
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  
}

