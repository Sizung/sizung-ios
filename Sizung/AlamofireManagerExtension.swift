//
//  AlamofireManagerExtension.swift
//  Sizung
//
//  Created by Markus Klepp on 13/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import Alamofire

extension Manager {
  public func jsonRequest(
    method: Alamofire.Method,
    _ URLString: URLStringConvertible,
      parameters: [String: AnyObject]? = nil,
      encoding: ParameterEncoding = .URL,
      headers: [String: String]? = ["Accept" : "application/json"])
    -> Request {
    return Manager.sharedInstance.request(
      method,
      URLString,
      parameters: parameters,
      encoding: encoding,
      headers: headers
    )
  }
}
