//
//  Conversation.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class Conversation: BaseModel {
  var attributes: ConversationAttributes!
  
  override func mapping(map: Map) {
    super.mapping(map)
    attributes <- map["attributes"]
  }
  
  class ConversationAttributes: Mappable {
    var title: String!
    var archived: Bool!
    var organization: Organization!
    var agenda_items: [AgendaItem]?
    var deliverables: [Deliverable]?
    var agenda_item_deliverables: [AgendaItemDeliverable]?
    var conversation_members: [ConversationMember]?
    
    required init?(_ map: Map) {
      
    }
    
    func mapping(map: Map) {
      title <- map["title"]
      archived <- map["archived"]
      archived <- map["archived"]
      organization <- map["organization"]
    }
  }

  
}
