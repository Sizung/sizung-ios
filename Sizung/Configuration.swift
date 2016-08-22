//
//  Configuration.swift
//  Sizung
//
//  Created by Markus Klepp on 12/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//


#if RELEASE_VERSION
let kBaseURL = "https://app.sizung.com"
let kWebsocketUrl = "wss://app.sizung.com/websocket"
#else
let kBaseURL = "https://staging-sizung.herokuapp.com"
let kWebsocketUrl = "wss://staging-sizung.herokuapp.com/websocket"
#endif


import Foundation
import SwiftKeychainWrapper

class Configuration: NSObject {

  class func BaseURL() -> String {
    return kBaseURL
  }

  class func APIEndpoint() -> String {
    return "\(kBaseURL)/api"
  }

  class func websocketEndpoint() -> String {
    return kWebsocketUrl
  }

  class func websocketOrigin() -> String {
    return kBaseURL
  }

  class func reset() {
    let appDomain = NSBundle.mainBundle().bundleIdentifier
    NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain!)
    KeychainWrapper.removeObjectForKey(Configuration.Settings.kDeviceId)
    KeychainWrapper.removeObjectForKey(Configuration.Settings.kSessionToken)
    KeychainWrapper.removeObjectForKey(Configuration.Settings.kLongLivedToken)
  }

  class func setDeviceId(deviceId: String) {
    KeychainWrapper.setString(deviceId, forKey: Configuration.Settings.kDeviceId)
  }

  class func getDeviceId() -> String? {
    return KeychainWrapper.stringForKey(Configuration.Settings.kDeviceId)
  }

  class func getSessionToken() -> String? {
    return KeychainWrapper.stringForKey(Configuration.Settings.kSessionToken)
  }

  class func setSessionToken(data: String) {
    KeychainWrapper.setString(data, forKey: Configuration.Settings.kSessionToken)
  }

  class func getLongLivedToken() -> String? {
    return KeychainWrapper.stringForKey(Configuration.Settings.kLongLivedToken)
  }

  class func setLongLivedToken(data: String) {
    KeychainWrapper.setString(data, forKey: Configuration.Settings.kLongLivedToken)
  }

  class func getSelectedOrganization() -> String? {
    return NSUserDefaults.standardUserDefaults().stringForKey(Configuration.Settings.kSelectedOrganization)
  }

  class func setSelectedOrganization(data: String) {
    NSUserDefaults.standardUserDefaults().setValue(data, forKey: Configuration.Settings.kSelectedOrganization)
    NSUserDefaults.standardUserDefaults().synchronize()
  }

  class func getLoginEmail() -> String? {
    return NSUserDefaults.standardUserDefaults().stringForKey(Configuration.Settings.kLoginEmail)
  }

  class func setLoginEmail(email: String) {
    NSUserDefaults.standardUserDefaults().setValue(email, forKey: Configuration.Settings.kLoginEmail)
    NSUserDefaults.standardUserDefaults().synchronize()
  }

  private struct Settings {
    static let kSessionToken = "AUTH_TOKEN"
    static let kLongLivedToken = "LONG_LIVED_TOKEN"
    static let kDeviceId = "V2::DEVICE_ID"
    static let kSelectedOrganization = "SELECTED_ORGANIZATION"
    static let kLoginEmail = "LOGIN_EMAIL"
  }

  struct NotificationConstants {
    static let kNotificationSessionTokenChanged = "NOTIFICATION_KEY_TOKEN_CHANGED"
    static let kNotificationKeyAuthError = "NOTIFICATION_KEY_AUTH_ERROR"
  }
}
