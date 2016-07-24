//
//  Error.swift
//  Sizung
//
//  Created by Markus Klepp on 28/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Crashlytics

enum Error {
  static func log(error: NSError) {
    #if RELEASE_VERSION
      Crashlytics.sharedInstance().recordError(error)
    #else
      print("error: \(error)")
    #endif
  }

  static func log(message: String) {
    #if RELEASE_VERSION
      Crashlytics.sharedInstance().recordError(Error.getError(message))
    #else
      print("error: \(message)")
    #endif
  }

  private static func getError(message: String) -> NSError {

    let userInfo = [
      NSLocalizedDescriptionKey: message
    ]

    return NSError(domain: "SizungErrorDomain", code: -message.hash, userInfo: userInfo)
  }
}
