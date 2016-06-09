//
//  ConversationMember.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import ObjectMapper

class ConversationMember: Mappable {
  var id: String!
  var user: User?
  var conversation: Conversation?
  
  required init?(_ map: Map) {
    
  }
  
  func mapping(map: Map) {
    user     <- map["user"]
    conversation  <- map["conversation"]
  }
}
