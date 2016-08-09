//
//  OrganzationMember.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class OrganizationMember: BaseModel {
  var memberId: String!
  var organizationId: String!

  override func mapping(map: Map) {
    super.mapping(map)
    memberId     <- map["relationships.member.data.id"]
    organizationId  <- map["relationships.organization.data.id"]
  }
}
