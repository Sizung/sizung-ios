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

  @IBInspectable var defaultImage: UIImage = R.image.default_avatar()! {
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
        let gravatar = Gravatar(emailAddress: user!.email)
        self.setTitle(user!.getInitials(), forState: .Normal)

        self.af_setBackgroundImageForState(
          .Normal,
          URL: gravatar.URL(size: size),
          placeHolderImage: nil,
          progress: nil,
          progressQueue: dispatch_get_main_queue(),
          completion: { response in
            if response.result.error == nil {
              self.setTitle(nil, forState: .Normal)
            }
        })

        self.backgroundColor = Color.SIZUNG
        self.setTitle(user!.getInitials(), forState: .Highlighted)
      }
    }
  }


  override func layoutSubviews() {
    super.layoutSubviews()
    self.layer.cornerRadius = size/2
    self.clipsToBounds = true
  }
}
