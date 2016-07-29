//
//  Helper.swift
//  Sizung
//
//  Created by Markus Klepp on 15/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import MobileCoreServices

class Helper {
  static func delay(delay: Double, closure: ()->()) {
    dispatch_after(
      dispatch_time(
        DISPATCH_TIME_NOW,
        Int64(delay * Double(NSEC_PER_SEC))
      ),
      dispatch_get_main_queue(), closure)
  }

  static func getMimeType(fileName: String) -> String {

    if let fileExtension = NSURL(string: fileName)!.pathExtension {
      let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil)!.takeRetainedValue()

      let mimeType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType)?.takeRetainedValue()

      guard mimeType != nil else {
        return "application/octet-stream"
      }

      if let mimeType = mimeType {
        return mimeType as String
      }
    }

    // should have returned before
    fatalError()
  }
}
