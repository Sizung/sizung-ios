//
//  UICustomFont.swift
//  Sizung
//
//  Created by Markus Klepp on 09/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

extension UIFont {
  
  class func preferredCustomFontForTextStyle(textStyle: String) -> UIFont {
  
    let font = UIFontDescriptor.preferredFontDescriptorWithTextStyle(textStyle)
    let fontSize: CGFloat = font.pointSize
    
    if textStyle == UIFontTextStyleHeadline || textStyle == UIFontTextStyleSubheadline {
      if let boldFont = UIFont(name: "BrandonGrotesque-Bold", size: fontSize) {
        return boldFont
      }
      else {
        NSLog("Fonts.plist is missing a value for the “Bold Font” key?")
        return UIFont.boldSystemFontOfSize(fontSize)
      }
    }
    else {
      if let regularFont = UIFont(name: "BrandonGrotesque-Medium", size: fontSize) {
        return regularFont
      }
      else {
        NSLog("Fonts.plist is missing a value for the “Regular Font” key?")
        return UIFont.systemFontOfSize(fontSize)
      }
    }
  }
  
//  public class func systemFontOfSize(fontSize: CGFloat) -> UIFont {
//    return preferredFontForTextStyle(<#T##textStyle: String##String#>)
//  }
//  class func boldSystemFontOfSize(fontSize: CGFloat) -> UIFont
//  class func italicSystemFontOfSize(fontSize: CGFloat) -> UIFont
}