//
//  TimelineDeliverableTableViewCell.swift
//  Sizung
//
//  Created by Markus Klepp on 14/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import AlamofireImage

class TimelineDeliverableTableViewCell: UITableViewCell {

  @IBOutlet weak var authorImage: UIImageView!
  @IBOutlet weak var assigneeImage: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var dueDateLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  
  static let kHeight:CGFloat = 158
  static let kHeightWithoutDueDate:CGFloat = kHeight - 21
  
  class var ReuseIdentifier: String { return "com.alamofire.identifier.\(self.dynamicType)" }
  
  // MARK: - Lifecycle Methods
  
  func configureAuthorImageWithURLString(URLString: String, placeholderImage: UIImage? = nil) {
    let size = authorImage.frame.size
    
    authorImage.af_setImageWithURL(
      NSURL(string: URLString)!,
      placeholderImage: placeholderImage,
      filter: AspectScaledToFillSizeWithRoundedCornersFilter(size: size, radius: 20.0),
      imageTransition: .CrossDissolve(0.2)
    )
  }
  
  func configureAssigneeImageWithURLString(URLString: String, placeholderImage: UIImage? = nil) {
    let size = assigneeImage.frame.size
    
    assigneeImage.af_setImageWithURL(
      NSURL(string: URLString)!,
      placeholderImage: placeholderImage,
      filter: AspectScaledToFillSizeWithRoundedCornersFilter(size: size, radius: 20.0),
      imageTransition: .CrossDissolve(0.2)
    )
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    clearImageView(authorImage)
    clearImageView(assigneeImage)
  }
  
  private func clearImageView(imageView: UIImageView?){
    guard imageView != nil else {
      return
    }
    
    imageView!.af_cancelImageRequest()
    imageView!.layer.removeAllAnimations()
    imageView!.image = nil
  }
}
