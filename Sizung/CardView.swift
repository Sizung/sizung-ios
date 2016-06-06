//
//  CardView.swift
//  Sizung
//
//  Created by Markus Klepp on 06/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class CardView: UIView {

  @IBInspectable var borderColor: UIColor? {
    didSet {
      layer.borderColor = borderColor?.CGColor
      layer.borderWidth = 1
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    layer.shadowOffset = CGSize(width: -0.2, height: 0.2)
    layer.shadowRadius = 1
    layer.shadowOpacity = 0.2;
  }

  
}
