//
//  User.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class User: BaseModel {
  var attributes: UserAttributes!
  var relationships: UserRelationships!
  
  override func mapping(map: Map) {
    super.mapping(map)
    attributes <- map["attributes"]
    relationships <- map["relationships"]
  }
  
  class UserAttributes: Mappable {
    var name: String!
    
    required init?(_ map: Map) {
      
    }
    
    func mapping(map: Map) {
      name <- map["name"]
    }
  }
  
  class UserRelationships: Mappable {
    
    required init?(_ map: Map) {
      
    }
    
    func mapping(map: Map) {
    }
  }
}

