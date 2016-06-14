//
//  BaseModel.swift
//  Sizung
//
//  Created by Markus Klepp on 01/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class BaseModel: Mappable, Equatable, Hashable {
  
  var id: String!
  var type: String!
  var created_at: NSDate?
  
  init(type: String) {
    id = NSUUID().UUIDString
    self.type = type
  }
  
  var hashValue: Int {
    return id.hashValue
  }
  
  required init?(_ map: Map) {
    
  }
  
  func mapping(map: Map) {
    id <- map["id"]
    type <- map["type"]
    created_at <- (map["attributes.created_at"], ISODateTimeTransform())
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
