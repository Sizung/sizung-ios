//
//  OrganizationViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 01/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import Sheriff
import KCFloatingActionButton

class OrganizationViewController: UIViewController, MainPageViewControllerDelegate {


  @IBOutlet weak var segmentedControl: SizungSegmentedControl!

  @IBOutlet weak var titleButton: UIButton!
  @IBOutlet weak var groupsButton: UIButton!
  @IBOutlet weak var floatingActionButton: KCFloatingActionButton!

  var groupsBadgeView = GIBadgeView()

  var mainPageViewController: MainPageViewController!

  var organizationsViewController: UIViewController?
  var conversationViewController: UIViewController?
  var groupsViewController: UIViewController?

  var loadingScreen = R.storyboard.main.initialViewController()!.view

  override func viewDidLoad() {
    super.viewDidLoad()

    groupsBadgeView.userInteractionEnabled = false
    groupsBadgeView.topOffset = 10
    groupsBadgeView.rightOffset = 10
    self.groupsButton.addSubview(groupsBadgeView)

    loadingScreen.frame = self.view.frame
    self.view.addSubview(loadingScreen)

    UIApplication.sharedApplication().statusBarStyle = .Default

    StorageManager.sharedInstance.unseenObjects.observeNext { _ in
      self.groupsBadgeView.badgeValue = self.calculateUnseenConversations()
      }.disposeIn(rBag)

    segmentedControl.items = ["PRIORITY", "STREAM", "ACTION"]
    segmentedControl.thumbColors = [Color.TODISCUSS, Color.STREAM, Color.TODO]
    segmentedControl.addTarget(
      self, action:
      #selector(self.segmentedControlDidChange),
      forControlEvents: .ValueChanged
    )

    self.initFloatingActionButton()
  }

  func initFloatingActionButton() {

    let priorityItem = KCFloatingActionButtonItem()
    priorityItem.buttonColor = Color.TODISCUSS
    priorityItem.title = "PRIORITY"
    priorityItem.icon = R.image.priority()
    priorityItem.iconImageView.tintColor = UIColor.whiteColor()
    priorityItem.iconImageView.contentMode = .ScaleAspectFit
    priorityItem.handler = addItem
    self.floatingActionButton.addItem(item: priorityItem)

    let groupItem = KCFloatingActionButtonItem()
    groupItem.buttonColor = Color.STREAM
    groupItem.title = "GROUP"
    groupItem.icon = R.image.group()
    groupItem.iconImageView.tintColor = UIColor.whiteColor()
    groupItem.iconImageView.contentMode = .ScaleAspectFit
    groupItem.handler = addItem
    self.floatingActionButton.addItem(item: groupItem)

    let deliverableItem = KCFloatingActionButtonItem()
    deliverableItem.buttonColor = Color.TODO
    deliverableItem.title = "TASK"
    deliverableItem.icon = R.image.action()
    deliverableItem.iconImageView.tintColor = UIColor.whiteColor()
    deliverableItem.iconImageView.contentMode = .ScaleAspectFit
    deliverableItem.handler = addItem
    self.floatingActionButton.addItem(item: deliverableItem)

  }

  func addItem(buttonItem: KCFloatingActionButtonItem) {
    print("add \(buttonItem.title)")
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        UIView.animateWithDuration(0.3, animations: {
          self.loadingScreen.alpha = 0
          UIApplication.sharedApplication().statusBarStyle = .LightContent

          // load conversation
          if let conversationViewController = self.conversationViewController {
            self.showViewController(conversationViewController, sender: nil)
            self.conversationViewController = nil
          }
        })
        self.titleButton.setTitle(storageManager.organization.name, forState: .Normal)
    }

  }

  func calculateUnseenConversations() -> Int {
    var unseenConversationSet = Set<String>()
    StorageManager.sharedInstance.unseenObjects.collection.forEach { unseenObject in
      if let conversationId = unseenObject.conversationId {
        unseenConversationSet.insert(conversationId)
      }
    }
    return unseenConversationSet.count
  }

  func segmentedControlDidChange(sender: SizungSegmentedControl) {

    let selectedIndex = sender.selectedIndex

    self.mainPageViewController.setSelectedIndex(selectedIndex)
  }

  @IBAction func showOrganizations(sender: AnyObject) {
    organizationsViewController = R.storyboard.organizations.initialViewController()
    self.showViewController(organizationsViewController!, sender: self)
  }

  @IBAction func hideOrganizations(sender: AnyObject) {
    organizationsViewController?.dismissViewControllerAnimated(true, completion: nil)
    organizationsViewController = nil
  }

  @IBAction func showGroups(sender: AnyObject) {
    groupsViewController = R.storyboard.conversations.initialViewController()
    self.showViewController(groupsViewController!, sender: self)
  }

  @IBAction func hideGroups(sender: AnyObject) {
    groupsViewController?.dismissViewControllerAnimated(true, completion: nil)
    groupsViewController = nil
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "embed" {
      if let mainPageViewController = segue.destinationViewController as? MainPageViewController {
        self.mainPageViewController = mainPageViewController
        self.mainPageViewController.mainPageViewControllerDelegate = self

        self.mainPageViewController.orderedViewControllers
          .append(R.storyboard.organization.agendaItemsTableViewController()!)
        self.mainPageViewController.orderedViewControllers
          .append(R.storyboard.organization.streamTableViewController()!)

        let deliverablesTableViewController =
          R.storyboard.organization.userDeliverablesTableViewController()!

        let token = AuthToken(data: Configuration.getAuthToken())
        let userId = token.getUserId()

        deliverablesTableViewController.userId = userId

        self.mainPageViewController.orderedViewControllers.append(deliverablesTableViewController)

      } else {
        fatalError("unexpected segue destinationViewcontroller " +
          "\(segue.destinationViewController.dynamicType)")
      }
    } else {
      fatalError("unexpected segue \(segue.identifier)")
    }

  }

  func mainpageViewController(
    mainPageViewController: MainPageViewController,
    didSwitchToIndex index: Int) {
    segmentedControl.selectedIndex = index
  }
}
