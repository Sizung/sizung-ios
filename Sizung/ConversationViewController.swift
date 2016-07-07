//
//  ConversationViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 07/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class ConversationViewController: UIViewController {

  @IBOutlet weak var titleButton: UIButton!

  var conversation: Conversation!

  var agendaItem: AgendaItem?
  var deliverable: Deliverable?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.titleButton.setTitle("@\(conversation.title)", forState: .Normal)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


  @IBAction func close(sender: AnyObject) {
    dismissViewControllerAnimated(true, completion: nil)
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if R.segue.conversationViewController.embedNavController(segue: segue) != nil {
      if let navController = segue.destinationViewController as? UINavigationController {
        if let conversationContentViewController = navController.viewControllers.first as? ConversationContentViewController {
          conversationContentViewController.conversation = self.conversation
        }
      } else {
        fatalError()
      }
    } else {
      fatalError()
    }
  }
}
