//
//  StreamObjects.swift
//  Sizung
//
//  Created by Markus Klepp on 23/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import DateTools

protocol StreamBaseObjectProtocol {
  var subject: BaseModel! { get }
}

class StreamObject: Hashable, DateSortable {
  var date: NSDate = NSDate.distantPast()

  var sortDate: NSDate { return date }
  var hashValue: Int { return date.hashValue }

  init() {

  }
}

class StreamBaseObject: StreamObject, StreamBaseObjectProtocol {

  var subject: BaseModel! { return nil }

  func updateLastActionDate(date: NSDate) {
    if date.isLaterThan(self.date) {
      self.date = date
    }
  }

  var mentionAuthors: Set<User>! = []
  var commentAuthors: Set<User>! = []

  override var sortDate: NSDate { return date }
  override var hashValue: Int { return subject.id.hashValue }

  var isEmpty: Bool {
    return mentionAuthors.isEmpty && commentAuthors.isEmpty
  }

}

class StreamDateObject: StreamObject {

  init(date: NSDate) {
    super.init()
    let beginningOfDay = NSCalendar.currentCalendar().startOfDayForDate(date)
    // 23:59:59
    self.date = beginningOfDay.dateByAddingHours(23).dateByAddingMinutes(59).dateByAddingSeconds(59)
  }

  func containsDate(date: NSDate) -> Bool {
    let dayPeriod = DTTimePeriod(size: .Day, startingAt: self.date)
    return dayPeriod.containsDate(date, interval: .Open)
  }
}

class StreamConversationObject: StreamBaseObject {
  let conversation: Conversation!

  override var subject: BaseModel! { return conversation }

  init(conversation: Conversation) {
    self.conversation = conversation
  }
}

class StreamActionObject: StreamBaseObject {
  let action: Deliverable!
  let author: User!
  let conversation: Conversation!

  override var subject: BaseModel! { return action }

  init(action: Deliverable, conversation: Conversation, author: User) {
    self.action = action
    self.conversation = conversation
    self.author = author
  }
}

class StreamAgendaObject: StreamBaseObject {
  let agenda: AgendaItem!
  let owner: User!
  let conversation: Conversation!

  override var subject: BaseModel! { return agenda }

  init(agenda: AgendaItem, conversation: Conversation, owner: User) {
    self.agenda = agenda
    self.conversation = conversation
    self.owner = owner
  }
}


func == (lhs: StreamObject, rhs: StreamObject) -> Bool {

  // compare by id if both are Streambaseobject else use date
  switch (lhs, rhs) {
  case (let lhs as StreamBaseObject, let rhs as StreamBaseObject):
    return lhs.subject.id == rhs.subject.id
  default:
    // group by day
    return lhs.sortDate == rhs.sortDate
  }
}
