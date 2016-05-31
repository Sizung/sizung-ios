//
//  SizungRouter.swift
//  Sizung
//
//  Created by Markus Klepp on 13/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import Alamofire
import SwiftKeychainWrapper

enum Router: URLRequestConvertible {
  
  case Login(email: String, password: String)
  case Organizations()
  case Logout()
  
  
  var method: Alamofire.Method {
    switch self {
    case .Login:
      return .POST
    case .Logout:
      return .DELETE
    default:
      return .GET
    }
  }
  
  var path: String {
    switch self {
    case .Login,
         .Logout:
      return "/session_tokens"
    case .Organizations:
      return "/organizations"
    }
  }
  
  // MARK: URLRequestConvertible
  
  var URLRequest: NSMutableURLRequest {
    
    let URL = NSURL(string: Configuration.APIEndpoint())!
    let mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(path))
    mutableURLRequest.HTTPMethod = method.rawValue
    mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    if let authToken = KeychainWrapper.stringForKey(Configuration.Settings.AUTH_TOKEN) {
      mutableURLRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
    }
    
    switch self {
    case .Login(let email, let password):
      let parameters = [
        "user": [
          "email": email,
          "password": password
        ]
      ]
      return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
    default:
      return mutableURLRequest
    }
  }
}