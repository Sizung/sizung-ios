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
  
  var ownerId: String!
  var assigneeId: String!
  var parentId: String!
  
  var sort_date: NSDate! {
    get {
      if let dueDate = self.due_on {
        return dueDate
      } else {
        return self.created_at
      }
    }
  }
  
  func setCompleted() {
    self.status = "resolved"
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
    ownerId <- map["relationships.owner.data.id"]
    assigneeId <- map["relationships.assignee.data.id"]
    parentId <- map["relationships.parent.data.id"]
  }
  
  //  polymorphic stuff
  override class func objectForMapping(map: Map) -> Mappable? {
    if let parentType: String = map["relationships.parent.data.type"].value() {
      switch parentType {
      case "conversations":
        return Deliverable(map)
      case "agenda_items":
        return AgendaItemDeliverable(map)
      default:
        return nil
      }
    }
    return nil
  }
}
