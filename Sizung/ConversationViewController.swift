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

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)

    UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: true)
  }

  @IBAction func titleClicked(sender: AnyObject) {
    if self.navController?.viewControllers.count == 1 {
      let createConversationViewController = R.storyboard.conversations.create()!
      createConversationViewController.conversation = conversation
      self.presentViewController(createConversationViewController, animated: true, completion: nil)
    } else {

      let transition = CATransition()
      transition.duration = 0.3
      transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
      transition.type = kCATransitionPush
      transition.subtype = kCATransitionFromBottom
      self.navController?.view.layer.addAnimation(transition, forKey: nil)

      self.navController?.popToRootViewControllerAnimated(false)
    }
  }

  @IBAction func close(sender: AnyObject) {

    // close if at conversation level or coming from direct open
    if self.navController?.viewControllers.count == 1 || openItem != nil {
      dismissViewControllerAnimated(true, completion: nil)
    } else {

      let transition = CATransition()
      transition.duration = 0.3
      transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
      transition.type = kCATransitionPush
      transition.subtype = kCATransitionFromBottom
      self.navController?.view.layer.addAnimation(transition, forKey: nil)

      self.navController?.popToRootViewControllerAnimated(false)
    }
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

    var duration = 0.2
    var titleColor: UIColor

    switch viewController {
    case is ConversationContentViewController:
      self.leftTitleConstraint.constant = 40
      titleColor = Color.BACKGROUND
      UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: true)
    default:
      self.leftTitleConstraint.constant = 11
      titleColor = Color.SEARCHBAR
      UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: true)
    }

    if openItem != nil {
      duration = 0
    }

    UIView.animateWithDuration(duration) {
      self.view.backgroundColor = titleColor
      self.view.layoutIfNeeded()
    }


//    print("count: \(navigationController.viewControllers.count)")
  }

  private func getParentViewController() -> UIViewController? {
    let navStack = self.navController!.viewControllers
    if navStack.count > 1 {
      return navStack[navStack.count - 1]
    } else {
      // is only view controller
      return nil
    }
  }
}
