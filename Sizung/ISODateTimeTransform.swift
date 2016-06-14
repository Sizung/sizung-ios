//
//  ISODateTimeTransform.swift
//  Sizung
//
//  Created by Markus Klepp on 14/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//


import ObjectMapper
public class ISODateTimeTransform: DateFormatterTransform {
  
  public init() {
    let formatter = NSDateFormatter()
    formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    
    super.init(dateFormatter: formatter)
  }
  
}