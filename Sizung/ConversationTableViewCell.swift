//
//  ConversationsTableViewCell.swift
//  Sizung
//
//  Created by Markus Klepp on 06/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//


import Alamofire
import AlamofireImage
import UIKit

class ConversationTableViewCell: UITableViewCell {

  @IBOutlet weak var unreadStatusView: UIView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var activeCountLabel: UILabel!
  @IBOutlet weak var activeImageViewsContainerView: UIView!

  var activeUsersImageViews: Array<UIImageView> = []

  class var ReuseIdentifier: String { return "com.alamofire.identifier.\(self.dynamicType)" }

  // MARK: - Lifecycle Methods

  func configureImageViewWithURLString(imageView: UIImageView, URLString: String, placeholderImage: UIImage? = nil) {
    let imageSize = activeImageViewsContainerView.frame.height
    let size = CGSize(width: imageSize, height: imageSize)

    imageView.af_setImageWithURL(
      NSURL(string: URLString)!,
      placeholderImage: placeholderImage,
      filter: AspectScaledToFillSizeWithRoundedCornersFilter(size: size, radius: 20.0),
      imageTransition: .CrossDissolve(0.2)
    )
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    activeUsersImageViews.forEach({ activeUserImageView in
      activeUserImageView.af_cancelImageRequest()
      activeUserImageView.layer.removeAllAnimations()
      activeUserImageView.image = nil
    })
  }
}
