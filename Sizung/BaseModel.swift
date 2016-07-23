//
//  BaseModel.swift
//  Sizung
//
//  Created by Markus Klepp on 01/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class BaseModel: Mappable, Equatable, Hashable, DateSortable, CustomStringConvertible {

  // a UUID String
  // swiftlint:disable:next variable_name
  var id: String!
  var type: String!
  var createdAt: NSDate!
  var updatedAt: NSDate!

  var hashValue: Int {
    return id.hashValue
  }

  var sortDate: NSDate {
    return createdAt
  }

  var description: String { get { return "\(self.type) id: \(self.id)" } }

  init(type: String) {
    id = NSUUID().UUIDString
    self.type = type
  }

  init(itemId: String, type: String) {
    self.id = itemId
    self.type = type
  }

  required init?(_ map: Map) {

  }

  func mapping(map: Map) {
    id <- map["id"]
    type <- map["type"]
    createdAt <- (map["attributes.created_at"], ISODateTimeTransform())
    updatedAt <- (map["attributes.updated_at"], ISODateTimeTransform())
  }

  //  polymorphic stuff
  class func objectForMapping(map: Map) -> Mappable? {
    if let type: String = map["type"].value() {
      switch type {
      case "conversations":
        return Conversation(map)
      case "users":
        return User(map)
      case "comments":
        return Comment(map)
      case "deliverables":
        if map["relationships.parent.data.type"].value() == "agenda_items" {
          return AgendaItemDeliverable(map)
        } else {
          return Deliverable(map)
        }
      case "agenda_items":
        return AgendaItem(map)
      case "unseen_objects":
        return UnseenObject(map)
      case "attachments":
        return Attachment(map)
      default:
        return nil
      }
    }
    return nil
  }
}

func == (lhs: BaseModel, rhs: BaseModel) -> Bool {
  return lhs.id == rhs.id
}
