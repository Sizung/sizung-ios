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
  @IBOutlet weak var authorImage: AvatarImageView!
  @IBOutlet weak var bodyLabel: UILabel!
  @IBOutlet weak var datetimeLabel: UILabel!

  static let kMinimumHeight: CGFloat = 65

  class var kReuseIdentifier: String { return "com.alamofire.identifier.\(self.dynamicType)" }

  override func prepareForReuse() {
    super.prepareForReuse()

    guard authorImage != nil else {
      return
    }
    authorImage.user = nil
  }
}
