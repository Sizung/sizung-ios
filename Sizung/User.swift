//
//  User.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import Spine

class User: Resource {
  var name: String?
  var organization: LinkedResourceCollection?
  var organization_member: LinkedResourceCollection?
  var conversation_member: LinkedResourceCollection?
  
  override class var resourceType: ResourceType {
    return "users"
  }
  
  override class var fields: [Field] {
    return fieldsFromDictionary([
      "name": Attribute(),
      "organization": ToManyRelationship(Organization),
      "organization_member": ToManyRelationship(OrganizationMember),
      "conversation_member": ToManyRelationship(ConversationMember)
      ])
  }
}
