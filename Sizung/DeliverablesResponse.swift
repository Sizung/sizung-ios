//
//  DeliverableResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 01/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class DeliverablesResponse: Mappable {
  
  var data: [Deliverable]!
  
  required init?(_ map: Map) {
    
  }
  
  // Mappable
  func mapping(map: Map) {
    data <- map["data"]
  }
}