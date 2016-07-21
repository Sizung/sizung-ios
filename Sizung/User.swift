//
//  User.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class User: BaseModel {

  typealias UserId = String

  var firstName: String!
  var lastName: String!
  var name: String!
  var email: String!
  var presenceStatus: String?

  init(userId: String) {
    super.init(type: "users")
    self.id = userId
  }

  required init?(_ map: Map) {
    super.init(map)
  }

  func isActive() -> Bool {
    return "online" == self.presenceStatus
  }

  func getInitials() -> String {
    if let firstName = firstName, lastName = lastName {
      return "\(firstName[firstName.startIndex])\(lastName[lastName.startIndex])"
    } else {
      return "??"
    }
  }

  override func mapping(map: Map) {
    super.mapping(map)
    firstName <- map["attributes.first_name"]
    lastName <- map["attributes.last_name"]
    name <- map["attributes.name"]
    email <- map["attributes.email"]
    presenceStatus <- map["attributes.presence_status"]
  }
}
