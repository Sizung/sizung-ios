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

  override func mapping(map: Map) {
    super.mapping(map)
    name <- map["attributes.name"]
  }
}
