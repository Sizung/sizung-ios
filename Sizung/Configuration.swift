//
//  Configuration.swift
//  Sizung
//
//  Created by Markus Klepp on 12/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//


//#if RELEASE_VERSION
let SERVER_URL = "https://app.sizung.com/api"
let WEBSOCKET_ORIGIN_URL = "https://app.sizung.com"
let WEBSOCKET_URL = "wss://app.sizung.com/websocket"
//#else
//let SERVER_URL = "https://staging-sizung.herokuapp.com/api"
//let WEBSOCKET_ORIGIN_URL = "https://staging-sizung.herokuapp.com"
//let WEBSOCKET_URL = "wss://staging-sizung.herokuapp.com/websocket"
//#endif


import Foundation
import SwiftKeychainWrapper

class Configuration: NSObject {
  
  class func APIEndpoint() -> String {
    return SERVER_URL
  }
  
  class func websocketEndpoint() -> String {
    return WEBSOCKET_URL
  }
  
  // remove path components from api endpoint
  class func websocketOrigin() -> String {
    return WEBSOCKET_ORIGIN_URL
  }
  
  class func getDeviceId() -> String {
    
    if let deviceId = KeychainWrapper.stringForKey(Configuration.Settings.DEVICE_ID) {
      return deviceId
    }else {
      let deviceId = NSUUID().UUIDString
      KeychainWrapper.setString(deviceId, forKey: Configuration.Settings.DEVICE_ID)
      return deviceId
    }
  }
  
  struct Settings {
    static let AUTH_TOKEN = "AUTH_TOKEN"
    static let DEVICE_ID = "DEVICE_ID"
    static let SELECTED_ORGANIZATION = "SELECTED_ORGANIZATION"
    
    static let NOTIFICATION_KEY_AUTH_ERROR = "NOTIFICATION_KEY_AUTH_ERROR"
  }
}