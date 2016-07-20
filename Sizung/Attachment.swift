//
//  Attachment.swift
//  Sizung
//
//  Created by Markus Klepp on 18/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class Attachment: BaseModel {

  var fileName: String!
  var fileSize: Int!
  var fileType: String!
  var fileUrl: String!
  var parentId: String!
  var parentType: String!

  init(fileName: String, fileSize: Int, fileType: String, parentId: String, parentType: String) {
    super.init(type: "attachments")
    self.fileName = fileName
    self.fileSize = fileSize
    self.fileType = fileType
    self.parentId = parentId
    self.parentType = parentType
  }

  required init?(_ map: Map) {
    super.init(map)
  }

  override func mapping(map: Map) {
    super.mapping(map)
    fileName <- map["attributes.file_name"]
    fileSize <- map["attributes.file_size"]
    fileType <- map["attributes.file_type"]
    fileUrl <- map["attributes.file_url"]
    parentId <- map["relationships.parent.data.id"]
    parentType <- map["relationships.parent.data.type"]
  }
}
