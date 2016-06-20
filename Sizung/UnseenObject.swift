//
//  UnseenObject.swift
//  Sizung
//
//  Created by Markus Klepp on 20/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class UnseenObject: BaseModel {
  
  var agendaItem: AgendaItem?
  var conversation: Conversation?
  var deliverable: Deliverable?
  var organization: Organization?
  var target: BaseModel!
  var user: User!
  
  override func mapping(map: Map) {
    super.mapping(map)
    agendaItem <- map["relationships.author.data"]
    conversation <- map["relationships.author.data"]
    deliverable <- map["relationships.commentable.data"]
    organization <- map["relationships.organization.data"]
    target <- map["relationships.target.data"]
    user <- map["relationships.user.data"]
  }
}