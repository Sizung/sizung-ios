//
//  AutoCompletionTableCell.swift
//  Sizung
//
//  Created by Markus Klepp on 10/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import AlamofireImage

class AutoCompletionTableCell: UITableViewCell {

  @IBOutlet weak var userImage: UIImageView!
  @IBOutlet weak var usernameLabel: UILabel!
  
  static let kMinimumHeight: CGFloat = 43
  
  class var ReuseIdentifier: String { return "com.alamofire.identifier.\(self.dynamicType)" }
  
  // MARK: - Lifecycle Methods
  
  func configureCellWithURLString(URLString: String, placeholderImage: UIImage? = nil) {
    let size = userImage.frame.size
    
    userImage.af_setImageWithURL(
      NSURL(string: URLString)!,
      placeholderImage: placeholderImage,
      filter: AspectScaledToFillSizeWithRoundedCornersFilter(size: size, radius: 20.0),
      imageTransition: .CrossDissolve(0.2)
    )
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    guard userImage != nil else {
      return
    }
    
    userImage.af_cancelImageRequest()
    userImage.layer.removeAllAnimations()
    userImage.image = nil
  }
  
}
