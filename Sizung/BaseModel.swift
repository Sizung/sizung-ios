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
  
  var hashValue: Int {
    return id.hashValue
  }
  
  required init?(_ map: Map) {
    
  }
  
  func mapping(map: Map) {
    id <- map["id"]
    type <- map["type"]
  }
  
//  polymorphic stuff
  class func objectForMapping(map: Map) -> Mappable? {
    if let type: String = map["type"].value() {
      switch type {
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
