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
import ActionCableClient
import AlamofireNetworkActivityIndicator

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, LoginDelegate, WebsocketDelegate, ItemLoadDelegate {

  var window: UIWindow?

  var loginViewController: LoginViewController?

  func application(
    application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?
    ) -> Bool {

    self.checkSettings()

    #if RELEASE_VERSION
      Fabric.with([Crashlytics.self])
    #endif

    NetworkActivityIndicatorManager.sharedManager.isEnabled = true

    self.registerNotifications()

    if let authToken = Configuration.getAuthToken() {
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
    if let userInfo = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey]
      as? [String: AnyObject] {
      self.application(application, didReceiveRemoteNotification: userInfo)
    }

    return true
  }

  func checkSettings() {
    if NSUserDefaults.standardUserDefaults().boolForKey("reset_on_launch") {
      Configuration.reset()

      // Reset user defaults
      let appDomain = NSBundle.mainBundle().bundleIdentifier!
      NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
    }
  }

  func registerNotifications() {
    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: #selector(self.showLogin),
      name: Configuration.NotificationConstants.kNotificationKeyAuthError,
      object: nil
    )
  }

  func switchToOrganization(orgId: String) {

    // reset storage
    StorageManager.sharedInstance.reset()
    Configuration.setSelectedOrganization(orgId)

    loadInitialViewController()
  }

  func loadInitialViewController() {
    if let selectedOrganizationId = Configuration.getSelectedOrganization() {
      // check if organization is valid and present
      StorageManager.sharedInstance.storageForOrganizationId(selectedOrganizationId)
        .onSuccess { storageManager in
          UIView.performWithoutAnimation {
            let organizationViewController = R.storyboard.organization.initialViewController()!
            self.window?.rootViewController?.showViewController(organizationViewController, sender: nil)
          }
        }
        .onFailure { error in
          switch error {
          case .NotFound,
            .NotAuthenticated:

            let organizationsViewController = R.storyboard.organizations.initialViewController()!
            self.window?.rootViewController?.showViewController(organizationsViewController, sender: nil)
            InAppMessage.showErrorMessage("The selected organization can't be found, please select one")
          default:
            InAppMessage.showErrorMessage("There seems to be a problem with the internet connection")
          }
      }
    } else {
      let organizationViewController = R.storyboard.organizations.initialViewController()!
      self.window?.rootViewController?.showViewController(organizationViewController, sender: nil)
    }
  }

  func showLogin() {
    guard loginViewController == nil else {
      return
    }
    // make sure we are on main thread
    dispatch_async(dispatch_get_main_queue()) {
      let loginViewController = R.storyboard.login.initialViewController()!
      loginViewController.loginDelegate = self

      self.window?.rootViewController?.showViewController(loginViewController, sender: self)

      self.loginViewController = loginViewController
    }
  }

  func loginSuccess(loginViewController: LoginViewController) {
    self.loginViewController = nil
    self.registerForPushNotifications()
    self.initWebsocketConnection()

    loginViewController.dismissViewControllerAnimated(true, completion: nil)
    self.loadInitialViewController()
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

  func initWebsocketConnection() {
    let authToken = AuthToken(data: Configuration.getAuthToken())

    authToken.validate()
      .onSuccess { _ in
        let websocket =  Websocket(authToken: authToken.data!)
        websocket.userWebsocketDelegate = self
        StorageManager.sharedInstance.websocket = websocket

        self.fetchUnseenObjects()
    }
  }

  func fetchUnseenObjects() {
    // update unseenobjects
    if let userId = AuthToken(data: Configuration.getAuthToken()).getUserId() {
      StorageManager.sharedInstance.listUnseenObjects(userId)

      // subscribe to user channel
      if let websocket = StorageManager.sharedInstance.websocket {
        websocket.userWebsocketDelegate = self
        websocket.followUser(userId)
      }
    }
  }

  // universal link support
  func application(
    application: UIApplication,
    continueUserActivity userActivity: NSUserActivity,
                         restorationHandler: ([AnyObject]?) -> Void
    ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
      if let url = userActivity.webpageURL {
        self.loadUrl(url)
      }
    }
    return false
  }

  // push notifications

  func registerForPushNotifications() {
    let application = UIApplication.sharedApplication()
    let notificationSettings = UIUserNotificationSettings(
      forTypes: [.Badge, .Sound, .Alert],
      categories: nil
    )

    application.registerUserNotificationSettings(notificationSettings)

    application.registerForRemoteNotifications()
  }

  func application(
    application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
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

  func application(
    application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: NSError
    ) {
    Error.log(error)
  }

  // foreground notification received
  func application(
    application: UIApplication,
    handleActionWithIdentifier identifier: String?,
                               forRemoteNotification userInfo: [NSObject : AnyObject],
                                                     completionHandler: () -> Void
    ) {

    print("handleRemoteActionWithIdentifier \(identifier) notification: \(userInfo)")

    completionHandler()
  }

  func application(
    application: UIApplication,
    didReceiveRemoteNotification userInfo: [NSObject : AnyObject]
    ) {
    if let urlString = userInfo["link"] as? String {
      if let url = NSURL(string: urlString) {
        // generate local notification if application is active
        if application.applicationState == .Active {
          print("received link \(url) while in foreground")
          // if let message = userInfo["aps"]!["alert"] as? String {
          //   let localNotification = UILocalNotification()
          //   localNotification.userInfo = userInfo
          //   localNotification.soundName = UILocalNotificationDefaultSoundName;
          //   localNotification.alertBody = message;
          //   UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
          // }
        } else {
          self.loadUrl(url)
        }
      }
    }
  }

  // websocket delegate

  func onConnectFailed() {
    InAppMessage.showErrorMessage("There has been an error connecting to Sizung")
  }

  func onDisconnected() {
    InAppMessage.showErrorMessage("You have been disconnected from Sizung")
  }

  func onReceived(unseenObject: BaseModel) {
    if let unseenObject = unseenObject as? UnseenObject {
      StorageManager.sharedInstance.unseenObjects.append(unseenObject)
    }
  }

  func onFollowSuccess(channelName: String) {
  }

  private func loadUrl(url: NSURL) -> Bool {

    if let pathComponents = url.pathComponents {
      guard pathComponents.count == 3 else {

        let message = "loadURL wrong number of path components: \(url)"
        Error.log(message)
        return false
      }

      let type = pathComponents[1]
      let itemId = pathComponents[2]

      // check for known types only
      guard ["agenda_items", "deliverables", "conversations", "attachments", "organizations"].contains(type) else {
        let message = "link to unknown type \(type) with id:\(itemId)"
        Error.log(message)
        return false
      }

      // check if logged in
      if let authToken = Configuration.getAuthToken() {
        let token = AuthToken(data: authToken)
        token.validate()
          .onSuccess { _ in
            self.openItem(type, itemId: itemId)
          }.onFailure { error in
            self.showLogin()
        }
      } else {
        self.showLogin()
      }
    }

    return true
  }

  func openItem(type: String, itemId: String) {
    let itemLoadingViewController = ItemLoadingViewController(nib: R.nib.itemLoadingViewController)
    itemLoadingViewController.type = type
    itemLoadingViewController.itemId = itemId

    itemLoadingViewController.itemloadDelegate = self

    self.window?.rootViewController = itemLoadingViewController
  }

  func onItemLoaded(organizationId: String, viewController: UIViewController?) {

    self.window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
    self.window?.rootViewController = R.storyboard.main.initialViewController()

    if organizationId != Configuration.getSelectedOrganization() {
      // reset storage
      StorageManager.sharedInstance.reset()
      Configuration.setSelectedOrganization(organizationId)
    }

    let organizationViewController = R.storyboard.organization.initialViewController()!
    organizationViewController.conversationViewController = viewController
    self.window?.rootViewController?.showViewController(organizationViewController, sender: nil)
  }
}
