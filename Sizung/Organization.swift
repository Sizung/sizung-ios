//
//  Organization.swift
//  Sizung
//
//  Created by Markus Klepp on 13/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class Organization: BaseModel {
  var attributes: OrganizationAttributes!
  
  override func mapping(map: Map) {
    super.mapping(map)
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