//
//  StreamConversationTableViewCell.swift
//  Sizung
//
//  Created by Markus Klepp on 23/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class StreamAgendaTableViewCell: StreamTableViewCell {

  @IBOutlet weak var ownerLabel: UILabel!
  @IBOutlet weak var conversationLabel: UILabel!

  override var streamObject: StreamBaseObject? {
    didSet {
      if let streamObject = streamObject as? StreamAgendaObject {
        self.titleButton.setTitle(streamObject.agenda.title, forState: .Normal)
        self.ownerLabel.text = streamObject.owner.fullName
        self.conversationLabel.text = streamObject.conversation.title
      }
    }
  }
}
