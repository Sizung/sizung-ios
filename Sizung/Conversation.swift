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
  var organization: Organization!
  var agenda_items: [AgendaItem]!
  var deliverables: [Deliverable]!
  var agenda_item_deliverables: [AgendaItemDeliverable]!
  var conversation_members: [ConversationMember]!
  
  override func mapping(map: Map) {
    super.mapping(map)
    title <- map["attributes.title"]
    archived <- map["attributes.archived"]
    archived <- map["attributes.archived"]
    organization <- map["attributes.organization"]
  }
}
