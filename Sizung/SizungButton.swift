//
//  SizungButton.swift
//
//
//  Created by Markus Klepp on 08/07/16.
//
//

import UIKit

@IBDesignable
class SizungButton: UIButton {

  @IBInspectable var minimumSize: CGFloat = 44 {
    didSet {
      self.sizeToFit()
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    addConstraints()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    addConstraints()
  }

  func addConstraints() {
    self.addConstraints([
      NSLayoutConstraint(item: self, attribute: .Width, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: minimumSize),
      NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: minimumSize)
      ])
  }
}
