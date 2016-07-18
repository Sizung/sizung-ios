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

  @IBOutlet weak var floatingActionButton: KCFloatingActionButton!
  override func viewDidLoad() {
    super.viewDidLoad()

    floatingActionButton.fabDelegate = self
  }

  func emptyKCFABSelected(fab: KCFloatingActionButton) {
    let createConversationViewController = R.storyboard.conversations.create()!
    self.showViewController(createConversationViewController, sender: nil)
  }
}
