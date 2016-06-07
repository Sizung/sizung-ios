//
//  AgendaItemDeliverables.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class AgendaItemDeliverable: BaseModel {
  var name: String?
  var agendaItem: AgendaItem?
  
  override func mapping(map: Map) {
    super.mapping(map)
    name    <- map["name"]
    agendaItem <- map["relationships.parent.data"]
  }
  
  
}