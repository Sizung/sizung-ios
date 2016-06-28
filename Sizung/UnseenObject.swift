//
//  UnseenObject.swift
//  Sizung
//
//  Created by Markus Klepp on 20/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class UnseenObject: BaseModel {
  
  var agendaItemId: String?
  var conversationId: String?
  var deliverableId: String?
  var organizationId: String?
  var targetId: String!
  var userId: String!
  
  override func mapping(map: Map) {
    super.mapping(map)
    agendaItemId <- map["relationships.agenda_item.data.id"]
    conversationId <- map["relationships.conversation.data.id"]
    deliverableId <- map["relationships.deliverable.data.id"]
    organizationId <- map["relationships.organization.data.id"]
    targetId <- map["relationships.target.data.id"]
    userId <- map["relationships.user.data.id"]
  }
}