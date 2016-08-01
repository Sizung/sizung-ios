//
//  ConfirmationHandler.swift
//  Sizung
//
//  Created by Markus Klepp on 01/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import Alamofire

class ConfirmationHandler {
  let token: String

  init(url: NSURL) {
    let urlComponents = NSURLComponents(string: url.URLString)!
    let queryItems = urlComponents.queryItems
    self.token = queryItems!.filter({$0.name == "confirmation_token"}).first!.value!
  }

  func confirm() {
    Alamofire.request(SizungHttpRouter.ConfirmationLink(token: self.token))
      .validate()
      .responseString { response in
        print(response)
    }
  }
}
