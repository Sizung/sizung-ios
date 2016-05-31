//
//  Organization.swift
//  Sizung
//
//  Created by Markus Klepp on 13/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class Organization: Mappable, Equatable, Hashable {
  var id: String!
  var attributes: OrganizationAttributes!
  
  var hashValue: Int {
    return id.hashValue
  }
  
  required init?(_ map: Map) {
    
  }
  
  func mapping(map: Map) {
    id <- map["id"]
    attributes <- map["attributes"]
  }
  
  class OrganizationAttributes: Mappable {
    var name: String!
    var conversations: [Conversation]?
    var owner: User?
    var organization_members: [OrganizationMember]?
    
    required init?(_ map: Map) {
      
    }
    
    func mapping(map: Map) {
      name     <- map["name"]
    }
  }
}

func ==(lhs: Organization, rhs: Organization) -> Bool {
  return lhs.id == rhs.id
}
