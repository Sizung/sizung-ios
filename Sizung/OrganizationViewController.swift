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

class OrganizationViewController: UIViewController, MainPageViewControllerDelegate, OrganizationTableViewDelegate {


  @IBOutlet weak var segmentedControl: SizungSegmentedControl!

  @IBOutlet weak var titleButton: UIButton!
  @IBOutlet weak var groupsButton: UIButton!

  var storageManager: OrganizationStorageManager?

  var groupsBadgeView = GIBadgeView()

  var mainPageViewController: MainPageViewController!

  var organizationsViewController: OrganizationsViewController?
  var conversationViewController: UIViewController?
  var groupsViewController: UIViewController?

  override func viewDidLoad() {
    super.viewDidLoad()

    groupsBadgeView.userInteractionEnabled = false
    groupsBadgeView.topOffset = 10
    groupsBadgeView.rightOffset = 10
    self.groupsButton.addSubview(groupsBadgeView)

    UIApplication.sharedApplication().statusBarStyle = .Default

    segmentedControl.items = ["PRIORITY", "STREAM", "ACTION"]
    segmentedControl.thumbColors = [Color.TODISCUSS, Color.STREAM, Color.TODO]
    segmentedControl.addTarget(
      self, action:
      #selector(self.segmentedControlDidChange),
      forControlEvents: .ValueChanged
    )

    UIApplication.sharedApplication().statusBarStyle = .LightContent

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in

        self.storageManager = storageManager

        // register for unseenobject changes
        storageManager.unseenObjects.observeNext { _ in
          let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT

          dispatch_async(dispatch_get_global_queue(priority, 0)) {
            let unseenCount = self.calculateUnseenConversations()
            dispatch_async(dispatch_get_main_queue()) {
              self.groupsBadgeView.badgeValue = unseenCount
            }
          }
          }.disposeIn(self.rBag)

        // load conversation
        if let conversationViewController = self.conversationViewController {
          self.showViewController(conversationViewController, sender: nil)
          self.conversationViewController = nil
        }
        self.titleButton.setTitle(storageManager.organization.name, forState: .Normal)
    }
  }

  func calculateUnseenConversations() -> Int {
    var unseenConversationSet = Set<String>()
    self.storageManager!.unseenObjects.collection.filter { unseenObject in
        return unseenObject.organizationId == Configuration.getSelectedOrganization()
      }.forEach { unseenObject in
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
    organizationsViewController?.organizationTableViewDelegate = self
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

  func organizationSelected(organization: Organization) {
    if organization.id != Configuration.getSelectedOrganization() {
      // dismiss organizationsviewcontroller
      self.dismissViewControllerAnimated(false) {
        // dismiss self
        self.dismissViewControllerAnimated(true) {
          if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            appDelegate.switchToOrganization(organization.id)
          }
        }
      }
    } else {
      self.hideOrganizations(self)
    }
  }
}
