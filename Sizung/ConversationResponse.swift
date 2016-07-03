//
//  ConversationResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 03/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class ConversationResponse: Mappable {

  var conversation: Conversation!

  required init?(_ map: Map) {

  }

  func mapping(map: Map) {
    conversation <- map["data"]
  }
}
