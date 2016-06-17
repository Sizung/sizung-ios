//
//  CommentTableViewCell.swift
//  Sizung
//
//  Created by Markus Klepp on 07/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import AlamofireImage
import UIKit

class CommentTableViewCell: UITableViewCell {
  @IBOutlet weak var authorImage: UIImageView!
  @IBOutlet weak var bodyLabel: UILabel!
  @IBOutlet weak var datetimeLabel: UILabel!
  
  static let kMinimumHeight:CGFloat = 65
  
  class var ReuseIdentifier: String { return "com.alamofire.identifier.\(self.dynamicType)" }
  
  // MARK: - Lifecycle Methods
  
  func configureCellWithURLString(URLString: String, placeholderImage: UIImage? = nil) {
    let size = authorImage.frame.size
    
    authorImage.af_setImageWithURL(
      NSURL(string: URLString)!,
      placeholderImage: placeholderImage,
      filter: AspectScaledToFillSizeWithRoundedCornersFilter(size: size, radius: 20.0),
      imageTransition: .CrossDissolve(0.2)
    )
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    guard authorImage != nil else {
      return
    }
    
    authorImage.af_cancelImageRequest()
    authorImage.layer.removeAllAnimations()
    authorImage.image = nil
  }
}
