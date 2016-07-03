//
//  SizungTableCellItem.swift
//  Sizung
//
//  Created by Markus Klepp on 24/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation

@objc protocol TableViewCellDisplayable {
  func getTableViewCellTitle() -> String

  optional func getTableViewCellSubtitle() -> String
}
