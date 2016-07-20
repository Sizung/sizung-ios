//
//  AttachmentResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 20/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class AttachmentResponse: Mappable {

  var attachment: Attachment!

  required init?(_ map: Map) {

  }

  func mapping(map: Map) {
    attachment <- map["data"]
  }
}
