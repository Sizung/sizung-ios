//
//  UILayerBorderColorExtension.swift
//  Sizung
//
//  Created by Markus Klepp on 08/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

extension CALayer {
  var borderUIColor: UIColor {
    set {
      self.borderColor = newValue.CGColor
    }

    get {
      return UIColor(CGColor: self.borderColor!)
    }
  }
}
