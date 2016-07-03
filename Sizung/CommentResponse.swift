//
//  CommentResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 10/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class CommentResponse: Mappable {

  var comment: Comment!

  required init?(_ map: Map) {

  }

  func mapping(map: Map) {
    comment <- map["data"]
  }
}
