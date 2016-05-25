//
//  BaseModel.swift
//  Sizung
//
//  Created by Markus Klepp on 25/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Spine

class BaseModel: Resource, TableViewCellDisplayable {
  func getTableViewCellTitle() -> String {
    return ""
  }
}