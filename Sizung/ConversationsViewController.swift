//
//  ConversationsViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 18/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import KCFloatingActionButton

class ConversationsViewController: UIViewController, KCFloatingActionButtonDelegate {

  var conversationTableViewController: ConversationsTableViewController?

  @IBOutlet weak var floatingActionButton: KCFloatingActionButton!
  override func viewDidLoad() {
    super.viewDidLoad()

    floatingActionButton.fabDelegate = self
  }

  func emptyKCFABSelected(fab: KCFloatingActionButton) {
    let createConversationViewController = R.storyboard.conversations.create()!
    self.showViewController(createConversationViewController, sender: nil)
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if R.segue.conversationsViewController.embedConversationList(segue: segue) != nil {
      if let conversationTableViewController = segue.destinationViewController as? ConversationsTableViewController {
        self.conversationTableViewController = conversationTableViewController
      } else {
        fatalError()
      }
    } else {
      fatalError()
    }
  }
}
