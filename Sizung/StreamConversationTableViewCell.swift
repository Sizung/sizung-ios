//
//  StreamConversationTableViewCell.swift
//  Sizung
//
//  Created by Markus Klepp on 23/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class StreamConversationTableViewCell: StreamTableViewCell {

  override var streamObject: StreamObject? {
    didSet {
      if let streamObject = streamObject as? StreamConversationObject {
        self.titleButton.setTitle(streamObject.conversation.title, forState: .Normal)
      }
    }
  }
}
