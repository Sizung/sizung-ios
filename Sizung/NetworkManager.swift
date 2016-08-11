//
//  NetworkManager.swift
//  Sizung
//
//  Created by Markus Klepp on 11/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import BrightFutures
import Alamofire
import ObjectMapper

struct NetworkManager {

  // networking queue
  static let networkQueue = dispatch_queue_create("\(NSBundle.mainBundle().bundleIdentifier).networking-queue", DISPATCH_QUEUE_CONCURRENT)

  static func makeRequest<T: Mappable>(urlRequest: URLRequestConvertible) -> Future<T, StorageError> {
    let promise = Promise<T, StorageError>()

    Alamofire.request(urlRequest)
      .validate()
      .responseJSON(queue: networkQueue) { response in
        switch response.result {
        case .Success(let JSON):
          if let typedResponse = Mapper<T>().map(JSON) {
            promise.success(typedResponse)
          }
        case .Failure
          where response.response?.statusCode == 401:

          loginWithToken()
            .onSuccess { tokenString in
              let sessionToken = AuthToken(data: tokenString)
              sessionToken.validateAndStore(.Session)

              NSNotificationCenter.defaultCenter().postNotificationName(Configuration.NotificationConstants.kNotificationSessionTokenChanged, object: nil)

              // retry
              makeRequest(urlRequest)
                .onSuccess { (typedResponse: T) in
                  promise.success(typedResponse)
                }.onFailure { error in
                  promise.failure(error)
              }

            }.onFailure { error in
              NSNotificationCenter.defaultCenter().postNotificationName(Configuration.NotificationConstants.kNotificationKeyAuthError, object: nil)
              promise.failure(.NotAuthenticated)
          }

        case .Failure
          where response.response?.statusCode == 404:
          promise.failure(.NotFound)
        case .Failure
          where response.response?.statusCode == 500:
          promise.failure(.NonRecoverable)
        case .Failure:
          handleOtherNetworkError(response)
          promise.failure(.Other)
        }
    }

    return promise.future
  }

  private static func handleOtherNetworkError(response: Response<AnyObject, NSError>) {
    if let error = response.result.error {
      switch error.code {
      // only log certain errors
      case -1001, // Timeout
      -1003, // A server with the specified hostname could not be found
      -1005, // The network connection was lost
      -1009, // The Internet connection appears to be offline.
      -1018: //  International roaming is currently off
        Log.error(error, response.request?.URLString).send()
      // report the rest
      default:
        var userInfo = error.userInfo

        if let urlString = response.request?.URLString {
          if let originalLocalizedDescription = userInfo[NSLocalizedDescriptionKey] {
            userInfo[NSLocalizedDescriptionKey] = "\(originalLocalizedDescription) url: \(urlString)"
          } else {
            userInfo[NSLocalizedDescriptionKey] = "failed for url: \(urlString)"
          }
        } else {
          fatalError()
        }

        let newError = NSError(domain: error.domain, code: error.code, userInfo: userInfo)
        Error.log(newError)
      }
    } else {
      Error.log("Something failed")
    }
  }

  private static func loginWithToken() -> Future<String, NSError> {
    let promise = Promise<String, NSError>()
    if let token = Configuration.getLongLivedToken() {
      Alamofire.request(SizungHttpRouter.LoginWithToken(longLivedToken: token))
        .validate()
        .responseJSON { response in
          switch response.result {
          case .Success(let JSON)
            where JSON.objectForKey("token") is String:

            let token = AuthToken(data: JSON["token"] as? String)

            token.validateAndStore(.Session)
              .onSuccess() { _ in
                promise.success(token.data!)
              }.onFailure() { error in
                let message = "token login error: \(error)"
                Log.message(message).send()
            }
          default:
            promise.failure(response.result.error!)
          }
      }
    } else {
      promise.failure(Error.getError("no long lived token found"))
    }
    return promise.future
  }

  static func updateLongLivedToken() {
    if let sessionToken = Configuration.getSessionToken() {
      Alamofire.request(SizungHttpRouter.GetLongLivedToken(sessionToken: sessionToken))
        .validate()
        .responseJSON { response in
          switch response.result {
          case .Success(let JSON)
            where JSON.objectForKey("token") is String:

            let token = AuthToken(data: JSON["token"] as? String)

            token.validateAndStore(.LongLived)
              .onFailure() { error in
                Log.message("token storage error: \(error)").send()
            }
          default:
            Log.message("token storage error: \(response.result.error!)").send()
          }
      }
    }
  }
}
