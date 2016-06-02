//
//  Deliverable.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

import ObjectMapper

class Deliverable: BaseModel {
  var attributes: DeliverableAttributes!
  var relationships: DeliverableRelationships!
  
  override func mapping(map: Map) {
    super.mapping(map)
    attributes <- map["attributes"]
    relationships <- map["relationships"]
  }
  
  class DeliverableAttributes: Mappable {
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
  
  class DeliverableRelationships: Mappable {
    //    var conversation: Conversation!
    var owner: UserResponse!
    //    var deliverables: Deliverable!
    
    required init?(_ map: Map) {
      
    }
    
    func mapping(map: Map) {
      //      conversation <- map["conversation"]
      owner <- map["owner"]
      //      deliverables <- map["deliverables"]
    }
  }
}
