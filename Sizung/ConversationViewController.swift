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

  var openItem: BaseModel?

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

          switch openItem {
          case let deliverable as Deliverable:
            let deliverableViewController = R.storyboard.deliverable.initialViewController()!
            deliverableViewController.deliverable = deliverable

            navController.pushViewController(deliverableViewController, animated: true)

          case let agendaItem as AgendaItem:
            let agendaItemViewController = R.storyboard.agendaItem.initialViewController()!
            agendaItemViewController.agendaItem = agendaItem

            navController.pushViewController(agendaItemViewController, animated: true)
          case nil:
            // nothing to do here
            break
          default:
            fatalError()
          }
        }
      } else {
        fatalError()
      }
    } else {
      fatalError()
    }
  }
}
