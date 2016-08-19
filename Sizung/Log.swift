//
//  Log.swift
//  Sizung
//
//  Created by Markus Klepp on 24/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Crashlytics

protocol SizungLog {
  var attributes: Dictionary<String, AnyObject>? { get }
  var name: String { get }
  func send()
}

enum EventType: String {
  case BACKGROUND_FETCH = "BACKGROUND_FETCH"
}

enum Log: SizungLog {
  case error(NSError, String?)
  case message(String)
  case event(EventType)


  var attributes: Dictionary<String, AnyObject>? {
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
    case .event:
      return nil
    }
  }

  var name: String {
    switch self {
    case .error,
         .message:
      return "Error"
    case .event(let type):
      return type.rawValue
    }
  }

  func send() {
    #if RELEASE_VERSION
      Answers.logCustomEventWithName(self.name, customAttributes: self.attributes)
    #else
      if let attributes = self.attributes {
        print("log: \(self.name) \(attributes)")
      } else {
        print("log: \(self.name)")
      }
    #endif
  }
}
