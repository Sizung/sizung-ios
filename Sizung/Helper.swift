//
//  Helper.swift
//  Sizung
//
//  Created by Markus Klepp on 15/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation

class Helper {
  static func delay(delay: Double, closure: ()->()) {
    dispatch_after(
      dispatch_time(
        DISPATCH_TIME_NOW,
        Int64(delay * Double(NSEC_PER_SEC))
      ),
      dispatch_get_main_queue(), closure)
  }
}
