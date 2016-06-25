//
//  BaseModel.swift
//  Sizung
//
//  Created by Markus Klepp on 01/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class BaseModel: Mappable, Equatable, Hashable, DateSortable {
  
  // a UUID String
  var id: String!
  var type: String!
  var created_at: NSDate!
  var updated_at: NSDate!
  
  init(type: String) {
    id = NSUUID().UUIDString
    self.type = type
  }
  
  var hashValue: Int {
    return id.hashValue
  }
  
  var sortDate: NSDate {
    return created_at
  }
  
  required init?(_ map: Map) {
    
  }
  
  func mapping(map: Map) {
    id <- map["id"]
    type <- map["type"]
    created_at <- (map["attributes.created_at"], ISODateTimeTransform())
    updated_at <- (map["attributes.updated_at"], ISODateTimeTransform())
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
        return Deliverable(map)
      case "agenda_items":
        return AgendaItem(map)
      case "unseen_objects":
        return UnseenObject(map)
      default:
        return nil
      }
    }
    return nil
  }
}

func ==(lhs: BaseModel, rhs: BaseModel) -> Bool {
  return lhs.id == rhs.id
}
