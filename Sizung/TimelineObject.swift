//
//  TimelineObject.swift
//  Sizung
//
//  Created by Markus Klepp on 05/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation

class TimelineObject: Hashable, DateSortable {
  let model: BaseModel?
  let newMessagesDate: NSDate?

  init(model: BaseModel) {
    self.model = model
    self.newMessagesDate = nil
  }

  init(newMessagesDate: NSDate) {
    self.newMessagesDate = newMessagesDate
    self.model = nil
  }

  var hashValue: Int {
    get {
      if let hashValue = model?.hashValue {
        return hashValue
      } else if let hashValue = newMessagesDate?.hashValue {
        return hashValue
      } else {
        return 0
      }
    }
  }

  var sortDate: NSDate {
    get {
      if let date = model?.createdAt {
        return date
      } else {
        return newMessagesDate!
      }
    }
  }
}

func == (lhs: TimelineObject, rhs: TimelineObject) -> Bool {
  return lhs.hashValue == rhs.hashValue
}

