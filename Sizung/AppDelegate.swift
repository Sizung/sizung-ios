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
class AppDelegate: UIResponder, UIApplicationDelegate, LoginDelegate, WebsocketDelegate {
  
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
          
          self.registerForPushNotifications()
          self.fetchUnseenObjects()
          
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
    self.registerForPushNotifications()
    
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
    
    self.fetchUnseenObjects()
  }
  
  func initWebsocketConnection(){
    if let authToken = KeychainWrapper.stringForKey(Configuration.Settings.AUTH_TOKEN) {
      StorageManager.sharedInstance.websocket = Websocket(authToken: authToken)
    }
  }
  
  func fetchUnseenObjects(){
    // update unseenobjects
    let authToken = AuthToken(data: KeychainWrapper.stringForKey(Configuration.Settings.AUTH_TOKEN))
    if let userId = authToken.getUserId() {
      StorageManager.sharedInstance.updateUnseenObjects(userId)
      
      // subscribe to user channel
      StorageManager.sharedInstance.websocket?.userWebsocketDelegate = self
      StorageManager.sharedInstance.websocket?.followUser(userId)
    }
  }
  
  func applicationWillTerminate(application: UIApplication) {
    print("applicationWillTerminate")
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  // universal links
  
  func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
      let url = userActivity.webpageURL
      
      print("received URL:\(url)")
    }
    return true
  }
  
  // push notifications
  
  func registerForPushNotifications() {
    let application = UIApplication.sharedApplication()
    let notificationSettings = UIUserNotificationSettings(
      forTypes: [.Badge, .Sound, .Alert], categories: nil)
    
    application.registerUserNotificationSettings(notificationSettings)
    
    application.registerForRemoteNotifications()
  }
  
  func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    let tokenChars = UnsafePointer<CChar>(deviceToken.bytes)
    var tokenString = ""
    
    for i in 0..<deviceToken.length {
      tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
    }
    
    Alamofire.request(SizungHttpRouter.RegisterDevice(token: tokenString))
      .validate()
      .responseJSON { response in
        print(response)
    }
  }
  
  func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    print("Failed to register:", error)
  }
  
  func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
    print("received remote notification: \(userInfo)")
  }
  
  func onReceived(conversationObject: BaseModel) {
    if let unseenObject = conversationObject as? UnseenObject {
      StorageManager.sharedInstance.unseenObjects.insert(unseenObject)
    } else {
      print(conversationObject)
    }
  }
  
  func onFollowSuccess(channelName: String) {
    print("follow user channel \(channelName)")
  }
  
}

