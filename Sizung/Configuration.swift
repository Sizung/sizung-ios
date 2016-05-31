//
//  Configuration.swift
//  Sizung
//
//  Created by Markus Klepp on 12/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//


#if RELEASE_VERSION
let SERVER_URL = "https://app.sizung.com/api"
#else
let SERVER_URL = "https://staging-sizung.herokuapp.com/api"
#endif


import Foundation

class Configuration: NSObject {
  
  class func APIEndpoint() -> String {
    return SERVER_URL
  }
  
  struct Settings {
    static let AUTH_TOKEN = "AUTH_TOKEN"
    static let SELECTED_ORGANIZATION = "SELECTED_ORGANIZATION"
  }
}