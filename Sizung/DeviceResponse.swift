//
//  DeviceResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 28/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class DeviceResponse: Mappable {

  var deviceId: String!

  required init?(_ map: Map) {

  }

  func mapping(map: Map) {
    deviceId <- map["data.id"]
  }
}
