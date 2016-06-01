//
//  OrganzationMember.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class OrganizationMember: Mappable {
  var id: String!
  var user: User?
  var organization: Organization?
  
  required init?(_ map: Map) {
  
  }
  
  func mapping(map: Map) {
    user     <- map["user"]
    organization     <- map["organization"]
  }
}
