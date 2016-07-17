//
//  MemberTableViewCell.swift
//  Sizung
//
//  Created by Markus Klepp on 17/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class MemberTableViewCell: UITableViewCell {

  @IBOutlet weak var avatarImage: AvatarImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var deleteButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
