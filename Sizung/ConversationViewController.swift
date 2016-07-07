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
  @IBOutlet weak var contentView: UIView!

  var conversation: Conversation!

  var agendaItem: AgendaItem?
  var deliverable: Deliverable?

  lazy var conversationContentViewController: ConversationContentViewController = {
    let viewController = R.storyboard.conversation.conversationContentViewController()!
    viewController.conversation = self.conversation
    return viewController
  }()

  lazy var agendaItemViewController: AgendaItemViewController = {
    let viewController = R.storyboard.agendaItem.initialViewController()!
    viewController.agendaItem = self.agendaItem
    return viewController
  }()

  lazy var deliverableViewController: DeliverableViewController = {
    let viewController = R.storyboard.deliverable.initialViewController()!
    viewController.deliverable = self.deliverable
    return viewController
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.titleButton.setTitle("@\(conversation.title)", forState: .Normal)

    self.embedViewController(conversationContentViewController)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


  @IBAction func close(sender: AnyObject) {
    dismissViewControllerAnimated(true, completion: nil)
  }

  func embedViewController(viewController: UIViewController) {
    self.addChildViewController(viewController)
    viewController.view.frame = self.contentView.frame
    self.contentView.addSubview(viewController.view)

    // make autolayout work
    viewController.view.translatesAutoresizingMaskIntoConstraints = false
    self.contentView.addConstraints( [
      NSLayoutConstraint (item: viewController.view, attribute: .Top, relatedBy: .Equal, toItem: self.contentView, attribute: .Top, multiplier: 1, constant: 0),
      NSLayoutConstraint (item: viewController.view, attribute: .Leading, relatedBy: .Equal, toItem: self.contentView, attribute: .Leading, multiplier: 1, constant: 0),
      NSLayoutConstraint (item: viewController.view, attribute: .Bottom, relatedBy: .Equal, toItem: self.contentView, attribute: .Bottom, multiplier: 1, constant: 0),
      NSLayoutConstraint (item: viewController.view, attribute: .Trailing, relatedBy: .Equal, toItem: self.contentView, attribute: .Trailing, multiplier: 1, constant: 0)
      ])
    viewController.didMoveToParentViewController(self)
  }

  func switchToChildViewController(viewController: UIViewController) {
    conversationContentViewController.willMoveToParentViewController(nil)
    self.addChildViewController(viewController)

    // Get the start frame of the new view controller and the end frame
    // for the old view controller. Both rectangles are offscreen.
    viewController.view.frame = self.contentView.frame
    let endFrame = self.contentView.frame

    let oldVC = conversationContentViewController
    let newVC = viewController

    self.transitionFromViewController(oldVC, toViewController: newVC, duration: 0.25, options: .TransitionNone, animations: {
      newVC.view.frame = oldVC.view.frame
      oldVC.view.frame = endFrame
      },
                                      completion: { finished in
                                        oldVC.removeFromParentViewController()
                                        newVC.didMoveToParentViewController(self)
    })
  }
}
