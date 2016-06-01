//
//  AgendaItem.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class AgendaItem: BaseModel {
  var attributes: AgendaItemAttributes!
  var relationships: AgendaItemRelationships!
  
  override func mapping(map: Map) {
    super.mapping(map)
    attributes <- map["attributes"]
    relationships <- map["relationships"]
  }
  
  class AgendaItemAttributes: Mappable {
    var title: String!
    var status: String!
    var archived: Bool!
    
    required init?(_ map: Map) {
      
    }
    
    func mapping(map: Map) {
      title <- map["title"]
      status <- map["status"]
      archived <- map["archived"]
    }
  }
  
  class AgendaItemRelationships: Mappable {
    var conversation: Conversation!
//    var owner: User!
//    var deliverables: Deliverable!
    
    required init?(_ map: Map) {
      
    }
    
    func mapping(map: Map) {
      conversation <- map["conversation"]
//      owner <- map["owner"]
//      deliverables <- map["deliverables"]
    }
  }
}
