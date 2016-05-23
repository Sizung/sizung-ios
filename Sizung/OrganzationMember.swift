//
//  OrganzationMember.swift
//  Sizung
//
//  Created by Markus Klepp on 16/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import Spine

class OrganizationMember: Resource {
  var user: User?
  var organization: Organization?
  
  override class var resourceType: ResourceType {
    return "organization_members"
  }
  
  override class var fields: [Field] {
    return fieldsFromDictionary([
      "user": ToOneRelationship(User),
      "organization": ToOneRelationship(Organization)
      ])
  }
}
