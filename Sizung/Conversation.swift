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
  var agendaItems: [AgendaItem]!
  var deliverables: [Deliverable]!
  var agendaItemDeliverables: [AgendaItemDeliverable]!
  var members: [User]!
  var new = false

  init(organizationId: String) {
    super.init(type: "conversations")
    self.organizationId = organizationId
    self.members = []
    self.new = true
  }

  required init?(_ map: Map) {
    super.init(map)
  }

  override func mapping(map: Map) {
    super.mapping(map)
    title <- map["attributes.title"]
    archived <- map["attributes.archived"]
    organizationId <- map["relationships.organization.data.id"]
    members <- map["relationships.members.data"]
    agendaItems <- map["relationships.agenda_items.data"]
    deliverables <- map["relationships.deliverables.data"]
    agendaItemDeliverables <- map["relationships.agenda_item_deliverables.data"]
  }
}
