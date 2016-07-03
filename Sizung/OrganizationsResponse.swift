//
//  OrganizationsResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 31/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class OrganizationsResponse: Mappable {

  var organizations: [Organization]!

  required init?(_ map: Map) {

  }

  // Mappable
  func mapping(map: Map) {
    organizations <- map["data"]
  }
}
