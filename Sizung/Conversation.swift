//
//  Conversation.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import Spine

class Conversation: Resource {
  var title: String?
  var archived: NSNumber?
  var organization: Organization?
  var agenda_items: LinkedResourceCollection?
  var deliverables: LinkedResourceCollection?
  var agenda_item_deliverables: LinkedResourceCollection?
  var conversation_members: LinkedResourceCollection?
  var members: LinkedResourceCollection?
  
  override class var resourceType: ResourceType {
    return "conversations"
  }
  
  override class var fields: [Field] {
    return fieldsFromDictionary([
      "title": Attribute(),
      "archived": Attribute(),
      "organization": ToOneRelationship(Organization),
      "agenda_items": ToManyRelationship(AgendaItem),
      "deliverables": ToManyRelationship(Deliverable),
      "agenda_item_deliverables": ToManyRelationship(AgendaItemDeliverable),
      "conversation_members": ToManyRelationship(ConversationMember),
      "members": ToManyRelationship(User)
      ])
  }
}
