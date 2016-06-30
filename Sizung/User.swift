//
//  User.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class User: BaseModel {
  var first_name: String!
  var last_name: String!
  var name: String!
  var email: String!
  var presence_status: String?
  
  init(id: String) {
    super.init(type: "users")
    self.id = id
  }
  
  required init?(_ map: Map) {
    super.init(map)
  }
  
  func isActive() -> Bool {
    return "online" == self.presence_status
  }
  
  func getInitials() -> String {
    return "\(first_name[first_name.startIndex])\(last_name[last_name.startIndex])"
  }
  
  override func mapping(map: Map) {
    super.mapping(map)
    first_name <- map["attributes.first_name"]
    last_name <- map["attributes.last_name"]
    name <- map["attributes.name"]
    email <- map["attributes.email"]
    presence_status <- map["attributes.presence_status"]
  }
}

