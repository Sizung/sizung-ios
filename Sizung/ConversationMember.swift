//
//  ConversationMember.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import ObjectMapper

class ConversationMember: BaseModel {
  var member: User!
  var conversation: Conversation!

  override func mapping(map: Map) {
    member     <- map["relationships.member.data"]
    conversation  <- map["relationships.conversation.data"]
  }
}
