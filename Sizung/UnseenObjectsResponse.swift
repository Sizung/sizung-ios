//
//  UnseenObjectsResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 20/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class UnseenObjectsResponse: Mappable {

  var unseenObjects: [UnseenObject]!
  var included: [BaseModel]!

  required init?(_ map: Map) {

  }

  func mapping(map: Map) {
    unseenObjects <- map["data"]
    included <- map["included"]
  }
}
