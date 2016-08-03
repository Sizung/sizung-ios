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
class AppDelegate: UIResponder, UIApplicationDelegate, OrganizationTableViewDelegate {

  var window: UIWindow?

  var loginViewController: LoginViewController?
  var organizationsViewController: OrganizationsViewController?

  private var reachabilityManager: NetworkReachabilityManager!

  func application(
    application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?
    ) -> Bool {

    self.checkSettings()

    #if RELEASE_VERSION
      Fabric.with([Crashlytics.self, Answers.self])
    #endif

    // set to dark style
    UINavigationBar.appearance().barStyle = .Black
    UINavigationBar.appearance().tintColor = UIColor.whiteColor()

    // network related stuff
    NetworkActivityIndicatorManager.sharedManager.isEnabled = true

    setupReachability()

    self.registerNotifications()

    if let authToken = Configuration.getAuthToken() {
      let token = AuthToken(data: authToken)
      token.validate()
        .onSuccess { _ in

          self.registerForPushNotifications()

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

  func setupReachability() {
    reachabilityManager = NetworkReachabilityManager(host: Configuration.APIEndpoint())
    reachabilityManager.listener = { status in
      switch status {
      case .NotReachable:
        // move error messages here
        break
      case .Reachable(_):
        self.initWebsocketConnection()
      case .Unknown:
        break
      }
    }
    reachabilityManager.startListening()
  }

  func switchToOrganization(orgId: String) {

    // reset storage
    StorageManager.sharedInstance.reset()
    Configuration.setSelectedOrganization(orgId)

    loadInitialViewController()
  }

  func logout() {
    Configuration.reset()
    StorageManager.sharedInstance.reset()

    self.window?.rootViewController = R.storyboard.main.initialViewController()

    showLogin()
  }

  func loadInitialViewController() {
    if let selectedOrganizationId = Configuration.getSelectedOrganization() {
      // check if organization is valid and present
      StorageManager.sharedInstance.storageForOrganizationId(selectedOrganizationId)
        .onSuccess { storageManager in
          let organizationViewController = R.storyboard.organization.initialViewController()!
          self.window?.rootViewController?.showViewController(organizationViewController, sender: nil)
        }
        .onFailure { error in
          switch error {
          case .NotFound,
          .NonRecoverable:
            let organizationsViewController = R.storyboard.organizations.initialViewController()!
            self.organizationsViewController = organizationsViewController
            organizationsViewController.organizationTableViewDelegate = self
            self.window?.rootViewController?.showViewController(organizationsViewController, sender: nil)
            InAppMessage.showErrorMessage("The selected organization can't be found, please select one")
          default:
            InAppMessage.showErrorMessage("There seems to be a problem with the internet connection")
          }

      }
    } else {
      let organizationsViewController = R.storyboard.organizations.initialViewController()!
      organizationsViewController.organizationTableViewDelegate = self
      self.organizationsViewController = organizationsViewController
      self.window?.rootViewController?.showViewController(organizationsViewController, sender: nil)
    }
  }

  func getPresentedViewController(viewController: UIViewController) -> UIViewController {

    if let presentedViewController = viewController.presentedViewController {
      return getPresentedViewController(presentedViewController)
    } else {
      return viewController
    }
  }

  func showLogin() {

    guard loginViewController == nil else {
      return
    }

    let email = Configuration.getLoginEmail()
    let currentTopViewController = self.getPresentedViewController(self.window!.rootViewController!)

    // make sure we are on main thread
    dispatch_async(dispatch_get_main_queue()) {

      let loginViewController = R.storyboard.login.initialViewController()!
      loginViewController.email = email
      loginViewController.loginDelegate = self

      currentTopViewController.showViewController(loginViewController, sender: self)

      self.loginViewController = loginViewController
    }
  }

  func initWebsocketConnection() {
    let authToken = AuthToken(data: Configuration.getAuthToken())

    authToken.validate()
      .onSuccess { _ in
        let websocket =  Websocket(authToken: authToken.data!)
        websocket.userWebsocketDelegate = self
        StorageManager.sharedInstance.websocket = websocket

        // subscribe to user channel for unseenobjects
        if let userId = AuthToken(data: Configuration.getAuthToken()).getUserId() {
          if let websocket = StorageManager.sharedInstance.websocket {
            websocket.userWebsocketDelegate = self
            websocket.followUser(userId)
          }
        }
    }
  }

  private func loadUrl(url: NSURL) -> Bool {
    if let pathComponents = url.pathComponents {
      guard pathComponents.count == 3 else {

        let message = "loadURL wrong number of path components: \(url)"
        Error.log(message)
        return false
      }

      if pathComponents[1] == "users" && pathComponents[2] == "confirmation"{
        //        let confirmationHandler = ConfirmationHandler(url: url)
        //        confirmationHandler.confirm()
        Alamofire.request(.GET, url.absoluteString)
          .responseString { response in
            InAppMessage.showSuccessMessage("Your email address has been successfully confirmed.\nYou can login now")
        }

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

  // universal link support
  func application(
    application: UIApplication,
    continueUserActivity userActivity: NSUserActivity,
                         restorationHandler: ([AnyObject]?) -> Void
    ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
      if let url = userActivity.webpageURL {
        return self.loadUrl(url)
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

    if let deviceId = Configuration.getDeviceId() {
      StorageManager.makeRequest(SizungHttpRouter.UpdateDevice(deviceId: deviceId, token: tokenString))
        .onSuccess { (deviceResponse: DeviceResponse) in
          Configuration.setDeviceId(deviceResponse.deviceId)
      }
    } else {
      StorageManager.makeRequest(SizungHttpRouter.RegisterDevice(token: tokenString))
        .onSuccess { (deviceResponse: DeviceResponse) in
          Configuration.setDeviceId(deviceResponse.deviceId)
      }
    }
  }

  func application(
    application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: NSError
    ) {
    // don't show simulator error
    if error.code != 3010 {
      Error.log(error)
    }
  }

  // foreground notification received
  func application(
    application: UIApplication,
    handleActionWithIdentifier identifier: String?,
                               forRemoteNotification userInfo: [NSObject : AnyObject],
                                                     completionHandler: () -> Void
    ) {
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

  func openItem(type: String, itemId: String) {
    Answers.logCustomEventWithName("Open Item at launch",
                                   customAttributes: [
                                    "type": type
      ])
    let itemLoadingViewController = ItemLoadingViewController(nib: R.nib.itemLoadingViewController)
    itemLoadingViewController.type = type
    itemLoadingViewController.itemId = itemId

    itemLoadingViewController.itemloadDelegate = self

    self.window?.rootViewController = itemLoadingViewController
  }

  // org selection delegate
  func organizationSelected(organization: Organization) {

    self.organizationsViewController?.dismissViewControllerAnimated(true) {
      self.organizationsViewController = nil
      self.switchToOrganization(organization.id)
    }
  }

}
