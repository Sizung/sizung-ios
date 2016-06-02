//
//  SizungRouter.swift
//  Sizung
//
//  Created by Markus Klepp on 13/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Alamofire
import SwiftKeychainWrapper

enum SizungHttpRouter: URLRequestConvertible {
  
  case Login(email: String, password: String)
  case Logout()
  case Organizations()
  case Organization(id: String)
  
  
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
    case .Organization(let id):
      return "/organizations/\(id)"
    }
  }
  
  // MARK: URLRequestConvertible
  
  var URLRequest: NSMutableURLRequest {
    
    let URL = NSURL(string: Configuration.APIEndpoint())!
    let mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(path))
    mutableURLRequest.HTTPMethod = method.rawValue
    mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    
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
      if let authToken = KeychainWrapper.stringForKey(Configuration.Settings.AUTH_TOKEN) {
        mutableURLRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
      }
      return mutableURLRequest
    }
  }
}