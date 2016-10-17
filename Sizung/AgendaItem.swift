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
  var conversationId: String!

  var ownerId: String!

  var new = false

  var number: Int? {
    guard let firstComponent = title.componentsSeparatedByString(" ").first else {
      return nil
    }
    return Int(firstComponent)
  }

  init(conversationId: String, ownerId: String) {
    super.init(type: "agenda_items")
    self.conversationId = conversationId
    self.ownerId = ownerId
    self.new = true
  }

  required init?(_ map: Map) {
    super.init(map)
  }

  func setResolved() {
    self.status = "resolved"
  }

  func isResolved() -> Bool {
    return "resolved" == self.status
  }

  func isOpen() -> Bool {
    return "open" == self.status
  }

  func getStatus() -> String {
    return self.status.capitalizedString
  }

  override func mapping(map: Map) {
    super.mapping(map)
    title <- map["attributes.title"]
    status <- map["attributes.status"]
    conversationId <- map["relationships.conversation.data.id"]
    ownerId <- map["relationships.owner.data.id"]
  }

  func isNumbered() -> Bool {
    return number != nil
  }
}
