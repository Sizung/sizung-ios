//
//  User.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class User: BaseModel {
  var name: String!
  
  override func mapping(map: Map) {
    super.mapping(map)
    name <- map["attributes.name"]
  }
}

