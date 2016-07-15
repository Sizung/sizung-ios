//
//  InAppMessage.swift
//  Sizung
//
//  Created by Markus Klepp on 03/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import SwiftyDrop

enum Custom: DropStatable {
  case Error

  var backgroundColor: UIColor? {
    switch self {
    case .Error: return .redColor()
    }
  }
  var font: UIFont? {
    switch self {
    case .Error: return R.font.brandonGrotesqueMedium(size: 15)
    }
  }
  var textColor: UIColor? {
    switch self {
    case .Error: return .whiteColor()
    }
  }
  var blurEffect: UIBlurEffect? {
    switch self {
    case .Error: return nil
    }
  }
}

class InAppMessage {

  static func showErrorMessage(text: String) {
    Drop.down(text, state: Custom.Error)
  }
}
