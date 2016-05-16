//
//  Organization.swift
//  Sizung
//
//  Created by Markus Klepp on 13/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import Spine

// Resource class
class Organization: Resource {
  var name: String?
  
  override class var resourceType: ResourceType {
    return "organizations"
  }
  
  override class var fields: [Field] {
    return fieldsFromDictionary([
      "name": Attribute(),
      ])
  }
}