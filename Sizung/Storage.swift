//
//  Storage.swift
//  Sizung
//
//  Created by Markus Klepp on 20/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation

class StorageManager {
//  singleton
  static let sharedInstance = StorageManager()
  private init() {}
  
  var isLoading: Bool = false
  var organizations: [Organization] = []
}
