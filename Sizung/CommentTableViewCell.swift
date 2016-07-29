//
//  CommentTableViewCell.swift
//  Sizung
//
//  Created by Markus Klepp on 07/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import AlamofireImage
import UIKit
import TTTAttributedLabel

class CommentTableViewCell: UITableViewCell, TTTAttributedLabelDelegate {
  @IBOutlet weak var authorImage: AvatarImageView!
  @IBOutlet weak var bodyLabel: TTTAttributedLabel!
  @IBOutlet weak var datetimeLabel: UILabel!

  static let kMinimumHeight: CGFloat = 65

  class var kReuseIdentifier: String { return "com.alamofire.identifier.\(self.dynamicType)" }


  override func awakeFromNib() {
    self.bodyLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
    self.bodyLabel.delegate = self
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    guard authorImage != nil else {
      return
    }
    authorImage.user = nil
  }

  func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
    UIApplication.sharedApplication().openURL(url)
  }

  override func canBecomeFirstResponder() -> Bool {
    return true
  }

  override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
    switch action.description {
    case "copy:":
      return true
    default:
      return false
    }
  }

  // MARK: - UIResponderStandardEditActions

  override func copy(sender: AnyObject?) {
    UIPasteboard.generalPasteboard().string = bodyLabel.text
  }
}
