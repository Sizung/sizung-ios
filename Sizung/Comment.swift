//
//  Comment.swift
//  Sizung
//
//  Created by Markus Klepp on 23/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class Comment: BaseModel {
  var body: String!
  var authorId: String!
  var commentable: BaseModel!
  var offline = false
  
  init(authorId: String, body: String, commentable: BaseModel){
    super.init(type: "comments")
    self.offline = true
    self.authorId = authorId
    self.body = body
    self.commentable = commentable
  }
  
  required init?(_ map: Map) {
    super.init(map)
  }
  
  override func mapping(map: Map) {
    super.mapping(map)
    body <- map["attributes.body"]
    authorId <- map["relationships.author.data.id"]
    commentable <- map["relationships.commentable.data"]
  }
}
