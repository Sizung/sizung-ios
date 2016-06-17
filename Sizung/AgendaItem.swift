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
  var conversation: Conversation!
  
  var owner: User!
  
  override func mapping(map: Map) {
    super.mapping(map)
    title <- map["attributes.title"]
    status <- map["attributes.status"]
    archived <- map["attributes.archived"]
    conversation <- map["relationships.conversation.data"]
    owner <- map["relationships.owner.data"]
  }
}
