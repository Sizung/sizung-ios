//
//  AgendaItem.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class AgendaItem: BaseModel {
  var title: String!
  var status: String!
  var archived: Bool!
  var conversationId: String!
  
  var ownerId: String!
  
  override func mapping(map: Map) {
    super.mapping(map)
    title <- map["attributes.title"]
    status <- map["attributes.status"]
    archived <- map["attributes.archived"]
    conversationId <- map["relationships.conversation.data.id"]
    ownerId <- map["relationships.owner.data.id"]
  }
}
