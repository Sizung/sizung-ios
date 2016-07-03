//
//  AgendaItemDeliverables.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class AgendaItemDeliverable: Deliverable {
  var agendaItemId: String!

  override func mapping(map: Map) {
    super.mapping(map)
    agendaItemId <- map["relationships.parent.data.id"]
  }
}
