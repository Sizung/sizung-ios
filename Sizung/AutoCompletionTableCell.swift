//
//  AutoCompletionTableCell.swift
//  Sizung
//
//  Created by Markus Klepp on 10/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import AlamofireImage

class AutoCompletionTableCell: UITableViewCell {

  @IBOutlet weak var userImage: AvatarImageView!
  @IBOutlet weak var usernameLabel: UILabel!
  
  static let kMinimumHeight: CGFloat = 43
  
  class var ReuseIdentifier: String { return "com.alamofire.identifier.\(self.dynamicType)" }
  
  // MARK: - Lifecycle Methods
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    guard userImage != nil else {
      return
    }
    
    userImage.user = nil
  }
  
}
