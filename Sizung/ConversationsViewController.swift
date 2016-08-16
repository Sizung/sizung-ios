//
//  ConversationsViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 18/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import KCFloatingActionButton

class ConversationsViewController: UIViewController, KCFloatingActionButtonDelegate, ConversationCreateDelegate {

  var conversationTableViewController: ConversationsTableViewController?

  var conversationTableViewDelegate: ConversationTableViewDelegate?

  @IBOutlet weak var floatingActionButton: KCFloatingActionButton!
  override func viewDidLoad() {
    super.viewDidLoad()

    floatingActionButton.fabDelegate = self
  }

  func emptyKCFABSelected(fab: KCFloatingActionButton) {
    let createConversationViewController = R.storyboard.conversations.create()!
    createConversationViewController.delegate = self
    self.presentViewController(createConversationViewController, animated: true, completion: nil)
  }

  func filterFor(filterString: String) {
    self.conversationTableViewController?.filterFor(filterString)
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if R.segue.conversationsViewController.embedConversationList(segue: segue) != nil {
      if let conversationTableViewController = segue.destinationViewController as? ConversationsTableViewController {
        self.conversationTableViewController = conversationTableViewController
        self.conversationTableViewController?.delegate = conversationTableViewDelegate
      } else {
        fatalError()
      }
    } else {
      fatalError()
    }
  }

  func conversationCreated(conversation: Conversation) {
    conversationTableViewDelegate?.conversationSelected(conversation)
  }
}
