//
//  ConversationViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 02/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class ConversationContentViewController: UIViewController, MainPageViewControllerDelegate {

  @IBOutlet weak var segmentedControl: SizungSegmentedControl!

  var mainPageViewController: MainPageViewController!

  var conversation: Conversation!

  override func viewDidLoad() {
    super.viewDidLoad()

    segmentedControl.items = ["PRIORITIES", "CHAT", "ACTIONS"]
    segmentedControl.thumbColors = [Color.TODISCUSS, Color.CHAT, Color.TODO]
    segmentedControl.addTarget(
      self,
      action: #selector(self.segmentedControlDidChange),
      forControlEvents: .ValueChanged
    )
  }

  func segmentedControlDidChange(sender: SizungSegmentedControl) {

    let selectedIndex = sender.selectedIndex

    self.mainPageViewController.setSelectedIndex(selectedIndex)
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if R.segue.conversationContentViewController.embed(segue: segue) != nil {
      if let mainPageViewController = segue.destinationViewController as? MainPageViewController {
        self.mainPageViewController = mainPageViewController
        self.mainPageViewController.mainPageViewControllerDelegate = self

        let agendaItemsTableViewController =
          R.storyboard.conversation.agendaItemsTableViewController()!
        agendaItemsTableViewController.conversation = self.conversation

        self.mainPageViewController.orderedViewControllers.append(agendaItemsTableViewController)

        let timelineTableViewController = R.storyboard.conversation.timelineTableViewController()!
        timelineTableViewController.timelineParent = self.conversation
        self.mainPageViewController.orderedViewControllers.append(timelineTableViewController)

        let deliverablesTableViewController =
          R.storyboard.conversation.conversationDeliverablesTableViewController()!
        deliverablesTableViewController.conversation = conversation
        self.mainPageViewController.orderedViewControllers.append(deliverablesTableViewController)
      } else {
        fatalError("unexpected destinationviewcontroller " +
          "\(segue.destinationViewController.dynamicType)")
      }
    } else {
      fatalError("unkown segue \(segue.identifier)")
    }
  }

  func mainpageViewController(
    mainPageViewController: MainPageViewController,
    didSwitchToIndex index: Int) {
      segmentedControl.selectedIndex = index
  }
}
