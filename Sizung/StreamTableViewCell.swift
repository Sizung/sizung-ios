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

class StreamTableViewCell: UITableViewCell {

  @IBOutlet weak var unreadStatusView: UIView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var lastCommentLabel: UILabel!
  @IBOutlet weak var lastCommentAuthorImageView: UIImageView!

  class var kReuseIdentifier: String { return "com.alamofire.identifier.\(self.dynamicType)" }

  // MARK: - Lifecycle Methods

  func configureCellWithURLString(URLString: String, placeholderImage: UIImage? = nil) {
    let size = lastCommentAuthorImageView.frame.size

    lastCommentAuthorImageView.af_setImageWithURL(
      NSURL(string: URLString)!,
      placeholderImage: placeholderImage,
      filter: AspectScaledToFillSizeWithRoundedCornersFilter(size: size, radius: 20.0),
      imageTransition: .CrossDissolve(0.2)
    )
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    lastCommentAuthorImageView.af_cancelImageRequest()
    lastCommentAuthorImageView.layer.removeAllAnimations()
    lastCommentAuthorImageView.image = nil
  }
}
