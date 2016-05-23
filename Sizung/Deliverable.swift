//
//  Deliverable.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import Spine

class Deliverable: Resource {
  var title: String?
  var conversation: Conversation?
  
  override class var resourceType: ResourceType {
    return "deliverables"
  }
  
  override class var fields: [Field] {
    return fieldsFromDictionary([
      "title": Attribute(),
      "conversation": ToOneRelationship(Conversation)
      ])
  }
}
