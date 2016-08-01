//
//  InAppMessage.swift
//  Sizung
//
//  Created by Markus Klepp on 03/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import SwiftyDrop

enum Custom: DropStatable {
  case Success
  case Error

  var backgroundColor: UIColor? {
    switch self {
    case .Success: return Color.SIZUNG
    case .Error: return .redColor()
    }
  }
  var font: UIFont? {
    return R.font.brandonGrotesqueMedium(size: 15)
  }
  var textColor: UIColor? {
    switch self {
    case .Success: return .whiteColor()
    case .Error: return .whiteColor()
    }
  }
  var blurEffect: UIBlurEffect? {
    return nil
  }
}

class InAppMessage {

  static func showSuccessMessage(text: String) {
    Drop.down(text, state: Custom.Success)
  }

  static func showErrorMessage(text: String) {
    Drop.down(text, state: Custom.Error)
  }
}
