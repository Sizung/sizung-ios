//
//  Deliverable.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class Deliverable: BaseModel {
  var title: String!
  var status: String!
  var archived: Bool!
  var conversation: Conversation!
  var due_on: NSDate?
  
  var owner: User!
  var assignee: User!
  var parent: BaseModel!
  
  override func mapping(map: Map) {
    super.mapping(map)
    title <- map["attributes.title"]
    status <- map["attributes.status"]
    due_on <- (map["attributes.due_on"], ISODateTransform())
    archived <- map["attributes.archived"]
    conversation <- map["relationships.conversation.data"]
    owner <- map["relationships.owner.data"]
    assignee <- map["relationships.assignee.data"]
    parent <- map["relationships.parent.data"]
  }
}
