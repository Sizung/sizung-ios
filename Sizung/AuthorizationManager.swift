//
//  AuthorizationManager.swift
//  Sizung
//
//  Created by Markus Klepp on 09/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import Alamofire

// TODO: move to storagemanager

public class AuthorizationManager: Manager {
  public typealias NetworkSuccessHandler = (AnyObject?) -> Void
  public typealias NetworkFailureHandler = (NSHTTPURLResponse?, AnyObject?, NSError) -> Void

  private typealias CachedTask = (NSHTTPURLResponse?, AnyObject?, NSError?) -> Void

  private var cachedTasks = Array<CachedTask>()
  private var isRefreshing = false

  public func startRequest(
    method method: Alamofire.Method,
           URLString: URLStringConvertible,
           parameters: [String: AnyObject]?,
           encoding: ParameterEncoding,
           success: NetworkSuccessHandler?,
           failure: NetworkFailureHandler?) -> Request?
  {
    let cachedTask: CachedTask = { [weak self] URLResponse, data, error in
      guard let strongSelf = self else { return }

      if let error = error {
        failure?(URLResponse, data, error)
      } else {
        strongSelf.startRequest(
          method: method,
          URLString: URLString,
          parameters: parameters,
          encoding: encoding,
          success: success,
          failure: failure
        )
      }
    }

    if self.isRefreshing {
      self.cachedTasks.append(cachedTask)
      return nil
    }

    // Append your auth tokens here to your parameters

    let request = self.request(method, URLString, parameters: parameters, encoding: encoding)

    request.response { [weak self] request, response, data, error in
      guard let strongSelf = self else { return }

      if let response = response where response.statusCode == 401 {
        strongSelf.cachedTasks.append(cachedTask)
        strongSelf.refreshTokens()
        return
      }

      if let error = error {
        failure?(response, data, error)
      } else {
        success?(data)
      }
    }

    return request
  }

  func refreshTokens() {
    self.isRefreshing = true

    // Make the refresh call and run the following in the success closure to restart the cached tasks

    let cachedTaskCopy = self.cachedTasks
    self.cachedTasks.removeAll()

    self.isRefreshing = false

    cachedTaskCopy.forEach { $0(nil, nil, nil) }

  }
}
