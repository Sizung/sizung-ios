//
//  Log.swift
//  Sizung
//
//  Created by Markus Klepp on 24/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Crashlytics

protocol SizungLog {
  var attributes: Dictionary<String, AnyObject> { get }
  func send()
}

enum Log: SizungLog {
  case error(NSError, String?)
  case message(String)


  var attributes: Dictionary<String, AnyObject> {
    switch self {
    case .error(let error, let additionalInfo):
      var attributes: Dictionary<String, AnyObject> = [
        "domain": error.domain,
        "code": error.code,
        "raw": error.debugDescription
      ]

      if let errorReason = error.userInfo[NSLocalizedFailureReasonErrorKey] {
        attributes["message"] = errorReason
      }

      if let additionalInfo = additionalInfo {
        attributes["additional_info"] = additionalInfo
      }
      return attributes

    case .message(let message):
      return [
        "domain": "SizungErrorDomain",
        "message": message
      ]
    }
  }

  func send() {
    #if RELEASE_VERSION
      Answers.logCustomEventWithName("Error", customAttributes: self.attributes)
    #else
      print("log: \(self.attributes)")
    #endif
  }
}
