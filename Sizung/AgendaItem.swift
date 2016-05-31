//
//  AgendaItem.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class AgendaItem: Mappable {
  var id: String!
  var title: String?
  var conversation: Conversation?
  
  required init?(_ map: Map) {
    
  }
  
  func mapping(map: Map) {
    title     <- map["title"]
    conversation  <- map["conversation"]
  }
}
