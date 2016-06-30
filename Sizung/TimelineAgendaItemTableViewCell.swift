//
//  TimelineAgendaItemTableViewCell.swift
//  Sizung
//
//  Created by Markus Klepp on 14/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import AlamofireImage

class TimelineAgendaItemTableViewCell: UITableViewCell {

  @IBOutlet weak var authorImage: AvatarImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  
  static let kHeight:CGFloat = 107
  
  class var ReuseIdentifier: String { return "com.alamofire.identifier.\(self.dynamicType)" }
  
  // MARK: - Lifecycle Methods
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    guard authorImage != nil else {
      return
    }
    
    authorImage.user = nil
  }
}
