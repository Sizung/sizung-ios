//
//  GetAttachmentUploadResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 20/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class GetAttachmentUploadResponse: Mappable {

  var signedUrl: String!

  required init?(_ map: Map) {

  }

  func mapping(map: Map) {
    signedUrl <- map["signedUrl"]
  }
}
