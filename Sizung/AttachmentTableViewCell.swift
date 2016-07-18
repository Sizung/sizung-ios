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

}
