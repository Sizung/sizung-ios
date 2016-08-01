//
//  BorderView.swift
//  Sizung
//
//  Created by Markus Klepp on 01/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

@IBDesignable class BorderView: UIView {

  @IBInspectable var borderWidth: CGFloat = 0 {
    didSet {
      layer.borderWidth = borderWidth
    }
  }
  @IBInspectable var borderColor: UIColor? {
    didSet {
      layer.borderColor = borderColor?.CGColor
    }
  }
}
