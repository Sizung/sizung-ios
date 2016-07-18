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

  init(agendaItemId: String) {
    super.init(type: "agenda_item_deliverables")
    self.agendaItemId = agendaItemId
    self.new = true
  }

  required init?(_ map: Map) {
    super.init(map)
  }

  override func mapping(map: Map) {
    super.mapping(map)
    agendaItemId <- map["relationships.parent.data.id"]
  }
}
