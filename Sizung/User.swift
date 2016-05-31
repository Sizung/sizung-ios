//
//  User.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class User: Mappable {
  var id: String!
  var name: String!
  var organization: [Organization]?
  var organization_member: [OrganizationMember]?
  var conversation_member: [ConversationMember]?
  
  required init?(_ map: Map) {
    
  }
  
  func mapping(map: Map) {
    name     <- map["name"]
    organization  <- map["organization"]
  }
}
