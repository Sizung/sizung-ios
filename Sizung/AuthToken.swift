//
//  TokenHandling.swift
//  Sizung
//
//  Created by Markus Klepp on 20/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import BrightFutures
import Result
import SwiftKeychainWrapper
import JWTDecode

enum TokenError : ErrorType {
  case InvalidToken
}

class AuthToken {
  
  var data: String?
  
  init(data: String?) {
    self.data = data
  }
  
  func validate() -> Future<String, TokenError> {
    let promise = Promise<String, TokenError>()
    if let userId = self.getUserId() {
      promise.success(userId)
    } else {
      promise.failure(TokenError.InvalidToken)
    }
    return promise.future
  }
  
  func validateAndStore() -> Future<Void, TokenError> {
    let promise = Promise<Void, TokenError>()
    
    self.validate()
      .onSuccess() { userId in
        KeychainWrapper.setString(self.data!, forKey: Configuration.Settings.AUTH_TOKEN)
        promise.success()
      }.onFailure() { error in
        promise.failure(error)
    }
    
    return promise.future
  }
  
  func getUserId() -> String? {
    do {
    let jwt = try decode(self.data!)
      return jwt.claim("user_id")
    }
    catch let error as NSError {
      print(error)
      return nil
    }
  }
}