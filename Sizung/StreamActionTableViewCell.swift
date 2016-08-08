//
//  StreamConversationTableViewCell.swift
//  Sizung
//
//  Created by Markus Klepp on 23/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class StreamActionTableViewCell: StreamTableViewCell {

  @IBOutlet weak var authorImageView: AvatarImageView!
  @IBOutlet weak var dueDateLabel: UILabel!
  @IBOutlet weak var conversationLabel: UILabel!

  override var streamObject: StreamBaseObject? {
    didSet {
      if let streamObject = streamObject as? StreamActionObject {
        self.titleButton.setTitle(streamObject.action.title, forState: .Normal)
        var dueDateString = "n/a"
        if let dueDate = streamObject.action.dueOn {
          dueDateString = DueDateHelper.getDueDateString(dueDate)
        }
        self.dueDateLabel.text = dueDateString
        self.conversationLabel.text = streamObject.conversation.title
        self.authorImageView.user = streamObject.author
      }
    }
  }
}
