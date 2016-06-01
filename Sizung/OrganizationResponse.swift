//
//  OrganizationResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 01/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class OrganizationResponse: Mappable {
  
  var data: Organization!
  var meta: OrganizationMeta!
  
  required init?(_ map: Map) {
    
  }
  
  func mapping(map: Map) {
    data <- map["data"]
    meta <- map["meta"]
  }
  
  class OrganizationMeta: Mappable {
    
    var conversations: ConversationsResponse!
    var agendaItems: AgendaItemsResponse!
    var deliverables: DeliverablesResponse!
    var conversationDeliverables: DeliverablesResponse!
    
    required init?(_ map: Map) {
      
    }
  
    func mapping(map: Map) {
      conversations <- map["conversations"]
      agendaItems <- map["agenda_items"]
      deliverables <- map["deliverables"]
      conversationDeliverables <- map["conversation_deliverables"]
    }
  }
}