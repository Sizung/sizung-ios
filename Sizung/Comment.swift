//
//  Comment.swift
//  Sizung
//
//  Created by Markus Klepp on 23/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class Comment: BaseModel {
  var body: String!
  var author: User!
  
  
  override func mapping(map: Map) {
    super.mapping(map)
    body <- map["attributes.body"]
    author <- map["relationships.author.data"]
  }
}
