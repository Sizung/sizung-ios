//
//  ConversationObjectResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 07/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class ConversationObjectsResponse: Mappable {
  
  var conversationObjects: [BaseModel]!
  var nextPageURL: String?
  
  required init?(_ map: Map) {
    
  }
  
  func mapping(map: Map) {
    conversationObjects <- map["data"]
    nextPageURL <- map["links.next"]
  }
}
