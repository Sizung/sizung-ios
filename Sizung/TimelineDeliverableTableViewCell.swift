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

  @IBOutlet weak var authorImage: AvatarImageView!
  @IBOutlet weak var assigneeImage: AvatarImageView!
  @IBOutlet weak var titleLabel: UIButton!
  @IBOutlet weak var dueDateLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  
  static let kHeight:CGFloat = 158
  static let kHeightWithoutDueDate:CGFloat = kHeight - 21
  
  class var ReuseIdentifier: String { return "com.alamofire.identifier.\(self.dynamicType)" }
  
  // MARK: - Lifecycle Methods
  

  override func prepareForReuse() {
    super.prepareForReuse()
    
    authorImage.user = nil
    assigneeImage.user = nil
  }
}
