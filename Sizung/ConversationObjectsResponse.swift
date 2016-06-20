//
//  ConversationObjectResponse.swift
//  Sizung
//
//  Created by Markus Klepp on 07/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper

class ConversationObjectsResponse: Mappable {
  
  var conversationObjects: [BaseModel]!
  var nextPageURL: String?
  
  var nextPage: Int? {
    get {
      guard (nextPageURL != nil) else {
        return nil
      }
      if let urlComponents = NSURLComponents(string: nextPageURL!){
        if let queryItems = urlComponents.queryItems {
          if let foundParam = queryItems.filter({$0.name == "page[number]"}).first {
            return Int(foundParam.value!)
          }
        }
      }
      return nil
    }
  }
  
  required init?(_ map: Map) {
    
  }
  
  func mapping(map: Map) {
    conversationObjects <- map["data"]
    nextPageURL <- map["links.next"]
  }
}
