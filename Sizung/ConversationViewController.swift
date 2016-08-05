//
//  ConversationViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 07/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class ConversationViewController: UIViewController, UINavigationControllerDelegate {

  var conversation: Conversation!

  var openItem: BaseModel?

  var navController: UINavigationController?

  @IBOutlet weak var titleButton: UIButton!
  @IBOutlet weak var conversationMemberButton: UIButton!
  @IBOutlet weak var leftTitleConstraint: NSLayoutConstraint!

  override func viewDidLoad() {
    self.titleButton.setTitle(self.conversation.title, forState: .Normal)
    self.conversationMemberButton.setTitle(String(self.conversation.members.count), forState: .Normal)
  }

  @IBAction func titleClicked(sender: AnyObject) {
    if self.navController?.viewControllers.count == 1 {
      let createConversationViewController = R.storyboard.conversations.create()!
      createConversationViewController.conversation = conversation
      self.presentViewController(createConversationViewController, animated: true, completion: nil)
    } else {
      self.navController?.popToRootViewControllerAnimated(true)
    }
  }

  @IBAction func close(sender: AnyObject) {
    dismissViewControllerAnimated(true, completion: nil)
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if R.segue.conversationViewController.embedNavController(segue: segue) != nil {
      if let navController = segue.destinationViewController as? UINavigationController {

        self.navController = navController

        navController.delegate = self

        if let conversationContentViewController = navController.viewControllers.first as? ConversationContentViewController {
          conversationContentViewController.conversation = self.conversation

          switch openItem {
          case let agendaItemDeliverable as AgendaItemDeliverable:
            StorageManager.sharedInstance.getAgendaItem(agendaItemDeliverable.agendaItemId)
              .onSuccess { parentAgendaItem in
                let agendaItemViewController = R.storyboard.agendaItem.initialViewController()!
                agendaItemViewController.agendaItem = parentAgendaItem

                navController.pushViewController(agendaItemViewController, animated: false)

                let deliverableViewController = R.storyboard.deliverable.initialViewController()!
                deliverableViewController.deliverable = agendaItemDeliverable

                navController.pushViewController(deliverableViewController, animated: false)
            }

          case let deliverable as Deliverable:

            let deliverableViewController = R.storyboard.deliverable.initialViewController()!
            deliverableViewController.deliverable = deliverable

            navController.pushViewController(deliverableViewController, animated: false)

          case let agendaItem as AgendaItem:
            let agendaItemViewController = R.storyboard.agendaItem.initialViewController()!
            agendaItemViewController.agendaItem = agendaItem

            navController.pushViewController(agendaItemViewController, animated: false)
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

  func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {

    var titleColor = Color.BACKGROUND

    if navigationController.viewControllers.count > 1 {
      self.leftTitleConstraint.constant = 11
      titleColor = Color.SEARCHBAR
    } else {
      self.leftTitleConstraint.constant = 40
    }

    UIView.animateWithDuration(0.2) {
      self.view.backgroundColor = titleColor
      self.view.layoutIfNeeded()
    }
  }
}
