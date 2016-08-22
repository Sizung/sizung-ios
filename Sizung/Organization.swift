//
//  Organization.swift
//  Sizung
//
//  Created by Markus Klepp on 13/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class Organization: BaseModel {
  var name: String!
  var ownerId: String!
  var new = false

  init(ownerId: String) {
    super.init(type: "organizations")
    self.ownerId = ownerId
    self.new = true
  }

  required init?(_ map: Map) {
    super.init(map)
  }

  override func mapping(map: Map) {
    super.mapping(map)
    name <- map["attributes.name"]
    ownerId <- map["relationships.owner.data.id"]
  }

  func getInitial() -> String {
    if let firstCharacter = name.characters.first {
      return String(firstCharacter).uppercaseString
    } else {
      return ""
    }
  }
}
