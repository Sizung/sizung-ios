//
//  AgendaItemDeliverables.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import Spine

class AgendaItemDeliverable: BaseModel {
  var name: String?
  var conversation: Conversation?
  
  override class var resourceType: ResourceType {
    return "agenda_item_deliverables"
  }
  
  override class var fields: [Field] {
    return fieldsFromDictionary([
      "name": Attribute(),
      "conversation": ToOneRelationship(Conversation)
      ])
  }
  
  override func getTableViewCellTitle() -> String {
    return name!
  }
}
