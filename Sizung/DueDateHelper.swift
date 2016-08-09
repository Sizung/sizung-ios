//
//  DueDateHelper.swift
//  Sizung
//
//  Created by Markus Klepp on 17/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import DateTools

class DueDateHelper {


  // Formats an incoming due date as String
  class func getDueDateString(dueDate: NSDate) -> String {
    if dueDate.isToday() {
      return "Due Today"
    } else if dueDate.isTomorrow() {
      return "Tomorrow"
    } else if dueDate.isYesterday() {
      return "Yesterday"
    } else if dueDate.daysAgo() > 0 {
      let formatter = NSDateFormatter()
      formatter.dateStyle = .MediumStyle
      formatter.timeStyle = .NoStyle

      return "\(formatter.stringFromDate(dueDate))"
    } else {
      let formatter = NSDateFormatter()
      formatter.dateStyle = .MediumStyle
      return formatter.stringFromDate(dueDate)
    }
  }
}
