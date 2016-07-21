//
//  StreamTableViewCell.swift
//  Sizung
//
//  Created by Markus Klepp on 06/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//


import Alamofire
import AlamofireImage
import UIKit

class StreamTableViewCell: UITableViewCell {

  @IBOutlet weak var titleButton: UIButton!
  @IBOutlet weak var streamItemContainerView: UIView!

  var title: String? {
    didSet {
      self.titleButton.setTitle(self.title, forState: .Normal)
    }
  }

  var streamObject: StreamObject? {
    didSet {
      if let streamObject = self.streamObject {
        switch streamObject.subject {
        case let conversation as Conversation:
          self.title = conversation.title
          self.titleButton.setBackgroundImage(R.image.bg_conversations(), forState: .Normal)
        case let agendaItem as AgendaItem:
          self.title = agendaItem.title
          self.titleButton.setBackgroundImage(R.image.bg_priorities(), forState: .Normal)
        case let deliverable as Deliverable:
          self.title = deliverable.title
          self.titleButton.setBackgroundImage(R.image.bg_actions(), forState: .Normal)
        default:
          fatalError("unkown streamobject \(streamObject.subject)")
        }

        print("show stuff for \(streamObject.subject)")
      } else {
        fatalError()
      }
    }
  }
}
