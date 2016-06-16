//
//  TimelineAgendaItemTableViewCell.swift
//  Sizung
//
//  Created by Markus Klepp on 14/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import AlamofireImage

class TimelineAgendaItemTableViewCell: UITableViewCell {

  @IBOutlet weak var authorImage: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  
  static let kHeight:CGFloat = 107
  
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
