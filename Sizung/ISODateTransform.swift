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
    formatter.dateFormat = "yyyy-MM-dd"
    
    super.init(dateFormatter: formatter)
  }
  
}
