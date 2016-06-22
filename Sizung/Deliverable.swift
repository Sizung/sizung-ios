//
//  Deliverable.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class Deliverable: BaseModel {
  var title: String!
  var status: String!
  var archived: Bool!
  var due_on: NSDate?
  
  var owner: User!
  var assignee: User!
  var parent: BaseModel!
  
  var conversation: Conversation {
    get {
      switch parent {
      case let conversation as Conversation:
        return conversation
      case let agendaItem as AgendaItem:
        return StorageManager.sharedInstance.getAgendaItem(agendaItem.id)!.conversation
      default:
        fatalError("unkown parent object in Deliverable \(self.id)")
      }
    }
  }
  
  var sort_date: NSDate! {
    get {
      if let dueDate = self.due_on {
        return dueDate
      } else {
        return self.created_at
      }
    }
  }
  
  func isCompleted() -> Bool {
    return "resolved" == self.status
  }
  
  func getStatus() -> String {
    return self.status.capitalizedString
  }
  
  override func mapping(map: Map) {
    super.mapping(map)
    title <- map["attributes.title"]
    status <- map["attributes.status"]
    due_on <- (map["attributes.due_on"], ISODateTransform())
    archived <- map["attributes.archived"]
    owner <- map["relationships.owner.data"]
    assignee <- map["relationships.assignee.data"]
    parent <- map["relationships.parent.data"]
  }
}
