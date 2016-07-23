//
//  StreamObjects.swift
//  Sizung
//
//  Created by Markus Klepp on 23/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation

protocol StreamObjectProtocol {
  var subject: BaseModel! { get }
}

class StreamObject: StreamObjectProtocol, Hashable, Equatable, DateSortable {

  var subject: BaseModel! { return nil }
  private var lastActionDate: NSDate! = NSDate.distantPast()

  func updateLastActionDate(date: NSDate) {
    if date.isLaterThan(lastActionDate) {
      lastActionDate = date
    }
  }

  var mentionAuthors: Set<User>! = []
  var commentAuthors: Set<User>! = []

  var sortDate: NSDate { return lastActionDate }
  var hashValue: Int { return subject.id.hashValue }
}

class StreamConversationObject: StreamObject {
  let conversation: Conversation!

  override var subject: BaseModel! { return conversation }

  init(conversation: Conversation) {
    self.conversation = conversation
  }
}

class StreamActionObject: StreamObject {
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

class StreamAgendaObject: StreamObject {
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
  return lhs.subject.id == rhs.subject.id
}
