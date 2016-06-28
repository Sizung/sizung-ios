//
//  Conversation.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class Conversation: BaseModel {
  var title: String!
  var archived: Bool!
  var organizationId: String!
  var agenda_items: [AgendaItem]!
  var deliverables: [Deliverable]!
  var agenda_item_deliverables: [AgendaItemDeliverable]!
  var members: [User]!
  
  override func mapping(map: Map) {
    super.mapping(map)
    title <- map["attributes.title"]
    archived <- map["attributes.archived"]
    organizationId <- map["relationships.organization.data.id"]
    members <- map["relationships.members.data"]
  }
}
