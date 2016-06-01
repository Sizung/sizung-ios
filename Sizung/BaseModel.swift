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
  
  var hashValue: Int {
    return id.hashValue
  }
  
  required init?(_ map: Map) {
    
  }
  
  func mapping(map: Map) {
    id <- map["id"]
  }
}


func ==(lhs: BaseModel, rhs: BaseModel) -> Bool {
  return lhs.id == rhs.id
}
