//
//  StreamDateTableViewCell.swift
//  Sizung
//
//  Created by Markus Klepp on 03/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import DateTools

class StreamDateTableViewCell: UITableViewCell {

  @IBOutlet weak var dateLabel: UILabel!

  func setDate(date: NSDate) {
    self.dateLabel.text = formatDate(date)
  }

  private func formatDate(date: NSDate) -> String {
    if date.isToday() {
      return "Today"
    } else if date.isYesterday() {
      return "Yesterday"
    } else {
      return date.formattedDateWithStyle(.MediumStyle)
    }
  }
}
