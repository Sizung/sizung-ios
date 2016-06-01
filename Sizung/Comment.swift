//
//  Comment.swift
//  Sizung
//
//  Created by Markus Klepp on 23/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class Comment: Mappable {
  var id: String!
  var author: User?
  var body: String?
  
  required init?(_ map: Map) {
    
  }
  
  func mapping(map: Map) {
    author     <- map["author"]
    body  <- map["body"]
  }
}
