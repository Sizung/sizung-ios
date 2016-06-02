//
//  UserResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 02/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class UserResponse: Mappable {
  
  var data: User!
  
  required init?(_ map: Map) {
    
  }
  
  func mapping(map: Map) {
    data <- map["data"]
  }
}