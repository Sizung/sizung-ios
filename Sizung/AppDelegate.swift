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
    
    // handle remote notification from launch
    if let userInfo = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [String: AnyObject] {
      self.application(application, didReceiveRemoteNotification: userInfo)
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
    
    //  show organization list if no organization is selected
    if !KeychainWrapper.hasValueForKey(Configuration.Settings.SELECTED_ORGANIZATION) {
      let organizationViewController = R.storyboard.organizations.initialViewController()!
      self.window?.rootViewController?.showViewController(organizationViewController, sender: nil)
    }
  }
  
  func showLogin(){
    // make sure we are on main thread
    dispatch_async(dispatch_get_main_queue()) {
      let loginViewController = R.storyboard.login.initialViewController()!
      loginViewController.loginDelegate = self
      loginViewController.modalPresentationStyle = .OverCurrentContext
      loginViewController.modalTransitionStyle = .CoverVertical
      
      self.window?.rootViewController = loginViewController
    }
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
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }
  
  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }
  
  func applicationDidBecomeActive(application: UIApplication) {
    
    //ensure websocket connection is open
    if let websocket = StorageManager.sharedInstance.websocket {
      if !websocket.client.connected {
        initWebsocketConnection()
      }
    } else {
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
      StorageManager.sharedInstance.listUnseenObjects(userId)
      
      // subscribe to user channel
      StorageManager.sharedInstance.websocket?.userWebsocketDelegate = self
      StorageManager.sharedInstance.websocket?.followUser(userId)
    }
  }
  
  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  // universal links
  
  func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
      if let url = userActivity.webpageURL {
        self.loadUrl(url)
      }
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
        if let error = response.result.error {
          Error.log(error)
        }
    }
  }
  
  func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    Crashlytics.sharedInstance().recordError(error)
  }
  
  // foreground notification received
  func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
    
    print("handleRemoteActionWithIdentifier \(identifier) notification: \(userInfo)")
    
    completionHandler()
  }
  
  func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
    if let urlString = userInfo["link"] as? String {
      if let url = NSURL(string: urlString) {
        // generate local notification if application is active
        if (application.applicationState == .Active){
          //          if let message = userInfo["aps"]!["alert"] as? String {
          //            let localNotification = UILocalNotification()
          //            localNotification.userInfo = userInfo
          //            localNotification.soundName = UILocalNotificationDefaultSoundName;
          //            localNotification.alertBody = message;
          //            UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
          //          }
        } else {
          self.loadUrl(url)
        }
      }
    }
  }
  
  func onReceived(unseenObject: BaseModel) {
    if let unseenObject = unseenObject as? UnseenObject {
      StorageManager.sharedInstance.unseenObjects.insert(unseenObject)
    }
  }
  
  func onFollowSuccess(channelName: String) {
  }
  
  private func loadUrl(url: NSURL){
    
    if let pathComponents = url.pathComponents {
      guard pathComponents.count == 3 else {
        
        let message = "loadURL wrong number of path components: \(url)"
        Error.log(message)
        return
      }
      
      // check if logged in
      if let authToken = KeychainWrapper.stringForKey(Configuration.Settings.AUTH_TOKEN) {
        let token = AuthToken(data: authToken)
        token.validate()
          .onSuccess { _ in
            
            let type = pathComponents[1]
            let id = pathComponents[2]
            
            // simplify organization loading
            switch type {
            case "agenda_items":
              StorageManager.sharedInstance.getAgendaItem(id)
                .onSuccess { agendaItem in
                  
                  StorageManager.sharedInstance.getConversation(agendaItem.conversationId)
                    .onSuccess { conversation in
                      // set selected organization according to entity
                      KeychainWrapper.setString(conversation.organizationId, forKey: Configuration.Settings.SELECTED_ORGANIZATION)
                      
                      let agendaItemViewController = R.storyboard.agendaItem.initialViewController()!
                      agendaItemViewController.agendaItem = agendaItem
                      
                      self.window?.rootViewController?.showViewController(agendaItemViewController, sender: self)
                  }
              }
              break
            case "deliverables":
              StorageManager.sharedInstance.getDeliverable(id)
                .onSuccess { deliverable in
                  
                  switch deliverable {
                  case let agendaItemDeliverable as AgendaItemDeliverable:
                    StorageManager.sharedInstance.getAgendaItem(agendaItemDeliverable.agendaItemId)
                      .onSuccess { agendaItem in
                        StorageManager.sharedInstance.getConversation(agendaItem.conversationId)
                          .onSuccess { conversation in
                            self.openDeliverable(deliverable, organizationId: conversation.organizationId)
                        }
                        
                    }
                  default:
                    StorageManager.sharedInstance.getConversation(deliverable.parentId)
                      .onSuccess { conversation in
                        self.openDeliverable(deliverable, organizationId: conversation.organizationId)
                    }
                  }
              }
              break
            case "conversations":
              StorageManager.sharedInstance.getConversation(id)
                .onSuccess { conversation in
                  // set selected organization according to entity
                  KeychainWrapper.setString(conversation.organizationId, forKey: Configuration.Settings.SELECTED_ORGANIZATION)
                  
                  let conversationsViewController = R.storyboard.conversations.conversationViewController()!
                  conversationsViewController.conversation = conversation
                  
                  self.window?.rootViewController?.showViewController(conversationsViewController, sender: self)
              }
              break
            default:
              let message = "link to unknown type \(type) with id:\(id)"
              Error.log(message)
            }
            
            
          }.onFailure { error in
            self.showLogin()
        }
      } else {
        self.showLogin()
      }
    }
  }
  
  func openDeliverable(deliverable: Deliverable, organizationId: String) {
    // set selected organization according to entity
    KeychainWrapper.setString(organizationId, forKey: Configuration.Settings.SELECTED_ORGANIZATION)
    
    let deliverableViewController = R.storyboard.deliverable.initialViewController()!
    deliverableViewController.deliverable = deliverable
    
    self.window?.rootViewController?.showViewController(deliverableViewController, sender: self)
  }
  
}

