//
//  ConversationsResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 01/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class ConversationsResponse: Mappable {
  
  var conversations: [Conversation]!
  
  required init?(_ map: Map) {
    
  }
  
  // Mappable
  func mapping(map: Map) {
    conversations <- map["data"]
  }
}