//
//  OrganizationMemberResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 09/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class OrganizationMemberResponse: Mappable {

  var member: OrganizationMember!

  required init?(_ map: Map) {

  }

  // Mappable
  func mapping(map: Map) {
    member <- map["data"]
  }
}
