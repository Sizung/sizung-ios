//
//  AvatarImageView.swift
//  Sizung
//
//  Created by Markus Klepp on 29/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import AlamofireImage

@IBDesignable class AvatarImageView: UIButton {
  
  @IBInspectable var defaultImage : UIImage = R.image.default_avatar()! {
    didSet {
      self.setBackgroundImage(defaultImage, forState: .Normal)
    }
  }
  
  var size: CGFloat {
    get {
      return self.frame.height
    }
  }
  
  var user: User? {
    didSet {
      if user != nil {
        let gravatar = Gravatar(emailAddress: user!.email, defaultImage: .Identicon)
        self.af_setBackgroundImageForState(.Normal, URL: gravatar.URL(size: size))
        
        self.setTitle(user!.name, forState: .Highlighted)
      }
    }
  }
  
  
  override func layoutSubviews() {
    super.layoutSubviews()
    self.layer.cornerRadius = size/2
    self.clipsToBounds = true
  }
}
