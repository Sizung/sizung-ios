//
//  AttachmentTableViewCell.swift
//  Sizung
//
//  Created by Markus Klepp on 18/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class AttachmentTableViewCell: UITableViewCell {

  @IBOutlet weak var previewImageView: UIImageView!
  @IBOutlet weak var filenameLabel: UILabel!
  @IBOutlet weak var filesizeLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  func setAttachment(attachment: Attachment) {
    self.filenameLabel.text = attachment.fileName
    self.filesizeLabel.text = NSByteCountFormatter.stringFromByteCount(Int64(attachment.fileSize), countStyle: .File)

    self.previewImageView.contentMode = .Center
    if attachment.fileSize < 2*1024*1024 {
      loadImageFromUrl(NSURL(string: attachment.fileUrl)!)
    } else {
      self.previewImageView.image = R.image.attachment_large()
    }
  }

  func loadImageFromUrl(url: NSURL) {
    self.previewImageView.af_setImageWithURL(
      url,
      placeholderImage: R.image.attachment_large(),
      filter: .None,
      progress: nil,
      progressQueue: dispatch_get_main_queue(),
      imageTransition: .None,
      runImageTransitionIfCached: false,
      completion: { response in
        switch response.result {
        case .Success:
          UIView.animateWithDuration(0.2) {
            self.previewImageView.contentMode = .ScaleAspectFit
          }
        case .Failure:
          self.previewImageView.contentMode = .Center
        }
    })
  }
}
