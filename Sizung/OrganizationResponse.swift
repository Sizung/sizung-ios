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
  var organizationDeliverablesResponse: DeliverablesResponse!
  var included: [BaseModel]!
  
  required init?(_ map: Map) {
    
  }
  
  func mapping(map: Map) {
    organization <- map["data"]
    conversationsResponse <- map["meta.conversations"]
    agendaItemsResponse <- map["meta.agenda_items"]
    organizationDeliverablesResponse <- map["meta.organization_deliverables"]
    included <- map["included"]
  }
}