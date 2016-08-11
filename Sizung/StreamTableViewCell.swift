//
//  StreamTableViewCell.swift
//  Sizung
//
//  Created by Markus Klepp on 06/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import AlamofireImage
import UIKit

class StreamTableViewCell: UITableViewCell {

  @IBOutlet weak var titleButton: UIButton!
  @IBOutlet weak var mentionsContainerView: UIView!
  @IBOutlet weak var mentionsLabel: UILabel!

  @IBOutlet weak var commentsContainerView: UIView!
  @IBOutlet weak var commentsLabel: UILabel!


  var title: String? {
    didSet {
      self.titleButton.setTitle(self.title, forState: .Normal)
    }
  }

  var streamObject: StreamBaseObject? {
    didSet {
      self.renderStreamItems()
    }
  }

  func setupContent(title: String, bgImage: UIImage?, leftContentInset: CGFloat) {
    self.title = title
    self.titleButton.setBackgroundImage(bgImage, forState: .Normal)
    self.titleButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: leftContentInset, bottom: 0, right: 20)
  }

  func renderStreamItems() {
    mentionsContainerView.subviews.forEach { subView in
      if subView is AvatarImageView {
        subView.removeFromSuperview()
      }
    }
    if streamObject?.mentionAuthors.count > 0 {
      mentionsContainerView.hidden = false
      fillMentionsView()
    } else {
      mentionsContainerView.hidden = true
    }

    commentsContainerView.subviews.forEach { subView in
      if subView is AvatarImageView {
        subView.removeFromSuperview()
      }
    }
    if streamObject?.commentAuthors.count > 0 {
      commentsContainerView.hidden = false
      fillCommentsView()
    } else {
      commentsContainerView.hidden = true
    }
  }

  func fillMentionsView() {

    let maxWidth = mentionsContainerView.frame.width - mentionsLabel.frame.width + 10

    var currentPos: CGFloat = 0
    let imageSize: CGFloat = 25

    var previousImageView: AvatarImageView?

    for mentionAuthor in (streamObject?.mentionAuthors)! {
      let imageView = getAvatarImageView(mentionAuthor)
      imageView.translatesAutoresizingMaskIntoConstraints = false
      imageView.addConstraints([
        NSLayoutConstraint(item: imageView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: imageSize),
        NSLayoutConstraint(item: imageView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: imageSize),
        ])

      currentPos += imageSize
      mentionsContainerView.addSubview(imageView)

      // add constraints
      if let previousImageView = previousImageView {
        imageView.leftAnchor.constraintEqualToAnchor(previousImageView.rightAnchor).active = true
      } else {
        imageView.leftAnchor.constraintEqualToAnchor(mentionsContainerView.leftAnchor).active = true
      }
      imageView.centerYAnchor.constraintEqualToAnchor(mentionsContainerView.layoutMarginsGuide.centerYAnchor).active = true

      previousImageView = imageView
      if currentPos > maxWidth {
        break
      }
    }

    let widthConstraint = mentionsLabel.leftAnchor.constraintEqualToAnchor(previousImageView?.rightAnchor)
    widthConstraint.constant = 10
    widthConstraint.active = true
  }

  func fillCommentsView() {

    let maxWidth = commentsContainerView.frame.width - commentsLabel.frame.width + 10

    var currentPos: CGFloat = 0
    let imageSize: CGFloat = 25

    var previousImageView: AvatarImageView?

    for commentAuthor in (streamObject?.commentAuthors)! {
      let imageView = getAvatarImageView(commentAuthor)
      imageView.translatesAutoresizingMaskIntoConstraints = false
      imageView.addConstraints([
        NSLayoutConstraint(item: imageView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: imageSize),
        NSLayoutConstraint(item: imageView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: imageSize),
        ])

      currentPos += imageSize
      commentsContainerView.addSubview(imageView)

      // add constraints
      if let previousImageView = previousImageView {
        imageView.leftAnchor.constraintEqualToAnchor(previousImageView.rightAnchor).active = true
      } else {
        imageView.leftAnchor.constraintEqualToAnchor(commentsContainerView.leftAnchor).active = true
      }
      imageView.centerYAnchor.constraintEqualToAnchor(commentsContainerView.layoutMarginsGuide.centerYAnchor).active = true

      previousImageView = imageView
      if currentPos > maxWidth {
        break
      }
    }

    let widthConstraint = commentsLabel.leftAnchor.constraintEqualToAnchor(previousImageView?.rightAnchor)
    widthConstraint.constant = 10
    widthConstraint.active = true
  }


  func getAvatarImageView(user: User) -> AvatarImageView {
    let imageView = AvatarImageView()
    imageView.user = user

    return imageView
  }

  func getLabel(text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = R.font.brandonTextRegular(size: 14)

    return label
  }
}
