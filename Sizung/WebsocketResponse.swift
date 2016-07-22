//
//  CommentWebsocketResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 13/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class WebsocketResponse: Mappable {

  var payload: BaseModel!
  var included: [BaseModel]! = []
  var action: String!

  required init?(_ map: Map) {

  }

  func mapping(map: Map) {
    payload <- map["payload.data"]
    included <- map["payload.included"]
    action <- map["action"]
  }
}
