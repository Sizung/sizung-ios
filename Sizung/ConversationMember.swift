//
//  ConversationMember.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import Spine

class ConversationMember: Resource {
  var user: User?
  var conversation: Conversation?
  
  override class var resourceType: ResourceType {
    return "conversation_members"
  }
  
  override class var fields: [Field] {
    return fieldsFromDictionary([
      "user": ToOneRelationship(User),
      "conversation": ToOneRelationship(Conversation)
      ])
  }
}
