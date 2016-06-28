//
//  DeliverableResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 01/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class DeliverableResponse: Mappable {
  
  var deliverable: Deliverable!
  var organizationId: String!
  
  required init?(_ map: Map) {
    
  }
  
  // Mappable
  func mapping(map: Map) {
    deliverable <- map["data"]
    organizationId <- map["included.0.id"]
  }
}