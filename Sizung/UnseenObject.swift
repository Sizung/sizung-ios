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
  var userId: String!
  var subscribed: Bool!

  var target: BaseModel?
  var timeline: BaseModel?

  override func mapping(map: Map) {
    super.mapping(map)
    subscribed <- map["attributes.subscribed"]
    agendaItemId <- map["relationships.agenda_item.data.id"]
    conversationId <- map["relationships.conversation.data.id"]
    deliverableId <- map["relationships.deliverable.data.id"]
    organizationId <- map["relationships.organization.data.id"]
    userId <- map["relationships.user.data.id"]
  }
}
