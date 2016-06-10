//
//  IsoDateFormatter.swift
//  Sizung
//
//  Created by Markus Klepp on 10/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

public class ISODateTransform: DateFormatterTransform {
  
  public init() {
    let formatter = NSDateFormatter()
    formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    
    "2016-05-04T12:23:46.504Z"
    
    super.init(dateFormatter: formatter)
  }
  
}
