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

enum TokenError: ErrorType {
  case InvalidToken
  case Expired
}

enum TokenType {
  case LongLived
  case Session
}

class AuthToken {

  var data: String?
  var jwt: JWT?

  init(data: String?) {

    self.data = data

    do {
      if self.data != nil {
        self.jwt = try decode(data!)
      }
    } catch let error as NSError {
      Error.log(error)
    }
  }

  func validate() -> Future<String, TokenError> {
    let promise = Promise<String, TokenError>()

    guard jwt != nil else {
      promise.failure(.InvalidToken)
      return promise.future
    }

    if jwt!.expired {
      promise.failure(.Expired)
    } else if let userId = self.getUserId() {
      promise.success(userId)
    } else {
      promise.failure(TokenError.InvalidToken)
    }
    return promise.future
  }

  func validateAndStore(type: TokenType) -> Future<Void, TokenError> {
    let promise = Promise<Void, TokenError>()

    self.validate()
      .onSuccess() { userId in
        switch type {
        case .LongLived:
          Configuration.setLongLivedToken(self.data!)
        case .Session:
          Configuration.setSessionToken(self.data!)
        }
        promise.success()
      }.onFailure() { error in
        promise.failure(error)
    }

    return promise.future
  }

  func getUserId() -> String? {
    guard jwt != nil else {
      return nil
    }

    return jwt!.claim("user_id")
  }
}
