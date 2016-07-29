//
//  Configuration.swift
//  Sizung
//
//  Created by Markus Klepp on 12/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//


#if RELEASE_VERSION
let kServerUrl = "https://app.sizung.com/api"
let kWebSocketOriginUrl = "https://app.sizung.com"
let kWebsocketUrl = "wss://app.sizung.com/websocket"
#else
let kServerUrl = "https://staging-sizung.herokuapp.com/api"
let kWebSocketOriginUrl = "https://staging-sizung.herokuapp.com"
let kWebsocketUrl = "wss://staging-sizung.herokuapp.com/websocket"
#endif


import Foundation
import SwiftKeychainWrapper

class Configuration: NSObject {

  class func APIEndpoint() -> String {
    return kServerUrl
  }

  class func websocketEndpoint() -> String {
    return kWebsocketUrl
  }

  class func websocketOrigin() -> String {
    return kWebSocketOriginUrl
  }

  class func reset() {
    let appDomain = NSBundle.mainBundle().bundleIdentifier
    NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain!)
    KeychainWrapper.removeObjectForKey(Configuration.Settings.kDeviceId)
    KeychainWrapper.removeObjectForKey(Configuration.Settings.kAuthToken)
  }

  class func setDeviceId(deviceId: String) {
    KeychainWrapper.setString(deviceId, forKey: Configuration.Settings.kDeviceId)
  }

  class func getDeviceId() -> String? {
    return KeychainWrapper.stringForKey(Configuration.Settings.kDeviceId)
  }

  class func getAuthToken() -> String? {
    return KeychainWrapper.stringForKey(Configuration.Settings.kAuthToken)
  }

  class func setAuthToken(data: String) {
    KeychainWrapper.setString(data, forKey: Configuration.Settings.kAuthToken)
  }

  class func getSelectedOrganization() -> String? {
    return NSUserDefaults.standardUserDefaults().stringForKey(Configuration.Settings.kSelectedOrganization)
  }

  class func setSelectedOrganization(data: String) {
    NSUserDefaults.standardUserDefaults().setValue(data, forKey: Configuration.Settings.kSelectedOrganization)
  }

  class func getLoginEmail() -> String? {
    return NSUserDefaults.standardUserDefaults().stringForKey(Configuration.Settings.kLoginEmail)
  }

  class func setLoginEmail(email: String) {
    NSUserDefaults.standardUserDefaults().setValue(email, forKey: Configuration.Settings.kLoginEmail)
  }

  private struct Settings {
    static let kAuthToken = "AUTH_TOKEN"
    static let kDeviceId = "V2::DEVICE_ID"
    static let kSelectedOrganization = "SELECTED_ORGANIZATION"
    static let kLoginEmail = "LOGIN_EMAIL"
  }

  struct NotificationConstants {
    static let kNotificationKeyAuthError = "NOTIFICATION_KEY_AUTH_ERROR"
  }
}
