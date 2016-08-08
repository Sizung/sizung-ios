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
  var dueOn: NSDate?

  var ownerId: String!
  var assigneeId: String!
  var parentId: String!

  var new = false

  override init(type: String) {
    super.init(type: type)
  }

  init(conversationId: String) {
    super.init(type: "deliverables")
    self.parentId = conversationId
    self.new = true
  }

  required init?(_ map: Map) {
    super.init(map)
  }

  override var sortDate: NSDate {
    get {
      if let dueDate = self.dueOn {
        return dueDate
      } else {
        return self.createdAt
      }
    }
  }

  func setCompleted() {
    self.status = "resolved"
  }

  func isCompleted() -> Bool {
    return "resolved" == self.status
  }

  func isOverdue() -> Bool {
    guard let dueOn = dueOn else {
      return false
    }

    guard !isCompleted() else {
      return false
    }

    return dueOn.daysAgo() >= 0
  }

  func getStatus() -> String {
    return self.status.capitalizedString
  }

  override func mapping(map: Map) {
    super.mapping(map)
    title <- map["attributes.title"]
    status <- map["attributes.status"]
    dueOn <- (map["attributes.due_on"], ISODateTransform())
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
