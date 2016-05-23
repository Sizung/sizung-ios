//
//  Comment.swift
//  Sizung
//
//  Created by Markus Klepp on 23/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import Spine

class Comment: Resource {
  var author: User?
  var body: String?
  
  override class var resourceType: ResourceType {
    return "comments"
  }
  
  override class var fields: [Field] {
    return fieldsFromDictionary([
      "author": ToOneRelationship(User),
      "body": Attribute()
      ])
  }
}
