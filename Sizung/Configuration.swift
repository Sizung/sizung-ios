//
//  Configuration.swift
//  Sizung
//
//  Created by Markus Klepp on 12/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//


#if RELEASE_VERSION
let SERVER_URL = "https://app.sizung.com/api"
let WEBSOCKET_URL = "wss://app.sizung.com/websocket"
#else
let SERVER_URL = "https://staging-sizung.herokuapp.com/api"
let WEBSOCKET_URL = "wss://staging-sizung.herokuapp.com/websocket"
#endif


import Foundation

class Configuration: NSObject {
  
  class func APIEndpoint() -> String {
    return SERVER_URL
  }
  
  class func websocketEndpoint() -> String {
    return WEBSOCKET_URL
  }
  
  struct Settings {
    static let AUTH_TOKEN = "AUTH_TOKEN"
    static let SELECTED_ORGANIZATION = "SELECTED_ORGANIZATION"
    
    static let NOTIFICATION_KEY_AUTH_ERROR = "NOTIFICATION_KEY_AUTH_ERROR"
  }
}