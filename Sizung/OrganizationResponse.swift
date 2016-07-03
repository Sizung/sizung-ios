//
//  OrganizationResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 01/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class OrganizationResponse: Mappable {

  var organization: Organization!
  var conversationsResponse: ConversationsResponse!
  var agendaItemsResponse: AgendaItemsResponse!
  var deliverablesResponse: DeliverablesResponse!
  var conversationDeliverablesResponse: DeliverablesResponse!
  var included: [BaseModel]!

  required init?(_ map: Map) {

  }

  func mapping(map: Map) {
    organization <- map["data"]
    conversationsResponse <- map["meta.conversations"]
    agendaItemsResponse <- map["meta.agenda_items"]
    deliverablesResponse <- map["meta.deliverables"]
    conversationDeliverablesResponse <- map["meta.conversation_deliverables"]
    included <- map["included"]
  }
}
