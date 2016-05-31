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

enum TokenError : ErrorType {
  case InvalidToken
}

class AuthToken {
  
  var data: String?
  
  init(data: String?) {
    self.data = data
  }
  
  func validate() -> Future<Void, TokenError> {
    let promise = Promise<Void, TokenError>()
    
    Queue.global.async {
      
      if self.data?.characters.count > 0 {
        promise.success()
      }
      else {
        promise.failure(TokenError.InvalidToken)
      }
    }
    
    return promise.future
  }
  
  func validateAndStore() -> Future<Void, TokenError> {
    let promise = Promise<Void, TokenError>()
    
    Queue.global.async {

      self.validate()
        .onSuccess() { payload in
          KeychainWrapper.setString(self.data!, forKey: Configuration.Settings.AUTH_TOKEN)
          promise.success(payload)
        }.onFailure() { error in
          promise.failure(error)
      }
    }
    
    return promise.future
  }
}