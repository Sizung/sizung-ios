//
//  Conversation.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import ObjectMapper

class Conversation: Mappable {
  var id: String!
  var title: String!
  var archived: Bool!
  var organization: Organization!
  var agenda_items: [AgendaItem]?
  var deliverables: [Deliverable]?
  var agenda_item_deliverables: [AgendaItemDeliverable]?
  var conversation_members: [ConversationMember]?
  
  required init?(_ map: Map){
    
  }
  
  func mapping(map: Map) {
    title <- map["title"]
    archived <- map["archived"]
    archived <- map["archived"]
    organization <- map["organization"]
  }
  
}
