//
//  DeliverablesTableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 25/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import ReactiveKit
import DateTools
import AKSegmentedControl

class DeliverablesTableViewController: UITableViewController {

  var collection: [Deliverable]?

  var parent: BaseModel?

  var storageManager: OrganizationStorageManager?

  var userId: String?
  var filter: Filter = .Mine

  @IBOutlet weak var segmentedControl: AKSegmentedControl!

  enum Filter {
    case Mine
    case All
  }

  override func viewDidLoad() {
    super.viewDidLoad()


    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.storageManager = storageManager
    }

    self.refreshControl?.addTarget(
      self,
      action: #selector(self.updateData),
      forControlEvents: UIControlEvents.ValueChanged
    )
    self.tableView.registerNib(
      R.nib.deliverableTableViewCell(),
      forCellReuseIdentifier: R.nib.deliverableTableViewCell.identifier
    )

    userId = AuthToken(data: Configuration.getAuthToken()).getUserId()

    self.initData()
    self.initSegmentedControl()
  }

  func initSegmentedControl() {
    let allButton = UIButton()
    allButton.setBackgroundImage(R.image.actions_filter_all(), forState: .Normal)
    allButton.setBackgroundImage(R.image.actions_filter_all_selected(), forState: .Selected)
    allButton.titleLabel?.font = R.font.brandonGrotesqueMedium(size: 15)
    allButton.setTitleColor(Color.ADDBUTTON, forState: .Normal)
    allButton.setTitleColor(UIColor.whiteColor(), forState: .Selected)
    allButton.setTitle("All", forState: .Normal)

    let myButton = UIButton()
    myButton.setBackgroundImage(R.image.actions_filter_mine(), forState: .Normal)
    myButton.setBackgroundImage(R.image.actions_filter_mine_selected(), forState: .Selected)
    myButton.titleLabel?.font = R.font.brandonGrotesqueMedium(size: 15)
    myButton.setTitleColor(Color.ADDBUTTON, forState: .Normal)
    myButton.setTitleColor(UIColor.whiteColor(), forState: .Selected)
    myButton.setTitle("My", forState: .Normal)

    segmentedControl.buttonsArray = [allButton, myButton]

    switch self.filter {
    case .All:
      segmentedControl.setSelectedIndex(0)
    case .Mine:
      segmentedControl.setSelectedIndex(1)
    }
  }

  @IBAction func filterValueChanged(sender: AKSegmentedControl) {
    switch sender.selectedIndexes.firstIndex {
    case 0:
      self.filter = .All
    case 1:
      self.filter = .Mine
    default:
      break
    }

    updateCollection()
  }

  func updateCollection() {
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.collection = storageManager.deliverables.collection.filter { deliverable in

          if self.parent != nil && self.parent!.id != deliverable.parentId {
            return false
          }

          if deliverable.archived == true {
            return false
          }

          if self.filter == .Mine {
            return deliverable.assigneeId == self.userId
          } else {
            return true
          }
        }

        self.collection!.sortInPlace { left, right in
          //        sort completed to bottom of list
          if left.isCompleted() && !right.isCompleted() {
            return false
          } else if !left.isCompleted() && right.isCompleted() {
            return true
            //        sort items with due date on top
          } else if left.dueOn != nil && right.dueOn == nil {
            return true
          } else if left.dueOn == nil && right.dueOn != nil {
            return false
            //        sort grouped items by sort_date
          } else {
            return left.sortDate.isEarlierThan(right.sortDate)
          }
        }


        self.tableView.tableFooterView?.hidden = self.collection!.count > 0

        self.tableView.reloadData()
    }
  }

  func initData() {
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in

        // listen to unseenObject changes
        storageManager.unseenObjects.observeNext { _ in
          self.tableView.reloadData()
          }.disposeIn(self.rBag)

        // listen to deliverable changes
        storageManager.deliverables.observeNext {_ in
          self.tableView.reloadData()
          }.disposeIn(self.rBag)
    }

    updateCollection()

  }

  override func viewDidAppear(animated: Bool) {
    if self.collection == nil {
      self.updateData()
    }
  }

  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.collection?.count ?? 0
  }

  func getConversationId(deliverable: Deliverable) -> String {
    switch deliverable {
    case let agendaItemDeliverable as AgendaItemDeliverable:
      return storageManager!.agendaItems[agendaItemDeliverable.agendaItemId]!.conversationId
    default:
      return deliverable.parentId
    }
  }

  override func tableView(
    tableView: UITableView,
    cellForRowAtIndexPath indexPath: NSIndexPath
    ) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCellWithIdentifier(
      R.nib.deliverableTableViewCell.identifier,
      forIndexPath: indexPath) as? DeliverableTableViewCell {

      if let deliverable = self.collection?[indexPath.row] {

        cell.titleLabel.text = deliverable.title

        cell.conversationLabel.text = storageManager!.conversations[getConversationId(deliverable)]?.title

        if deliverable.dueOn != nil && !deliverable.isCompleted() {
          cell.statusLabel.text = DueDateHelper.getDueDateString(deliverable.dueOn!)
        } else {
          cell.statusLabel.text = deliverable.getStatus()
        }

        var statusColor = UIColor(red:0.88, green:0.67, blue:0.71, alpha:1.0)
        var textStatusColor = UIColor.darkTextColor()

        if deliverable.isCompleted() {
          statusColor = UIColor(red:0.33, green:0.75, blue:0.59, alpha:1.0)
          textStatusColor = statusColor
        } else if deliverable.isOverdue() {
          //overdue or today
          statusColor = UIColor(red:0.98, green:0.40, blue:0.38, alpha:1.0)
          textStatusColor = statusColor
        }

        cell.statusView.backgroundColor = statusColor
        cell.statusView.layer.borderColor = statusColor.CGColor
        cell.statusLabel.textColor = textStatusColor

        let unseenObjects = self.storageManager!.unseenObjects

        let hasUnseenObjects = unseenObjects.collection.contains { obj in
          return obj.deliverableId == deliverable.id
        }

        if !deliverable.isCompleted() && !hasUnseenObjects {
          cell.statusView.backgroundColor = UIColor.clearColor()
        }
        cell.unreadStatusView.alpha = hasUnseenObjects ? 1 : 0
        return cell
      } else {
        fatalError("self.collection not set, count: \((self.collection?.count ?? 0))")
      }
    } else {
      fatalError("Unexpected cell type")
    }
  }

  func updateData() {

    self.refreshControl?.beginRefreshing()
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        storageManager.listDeliverables()
          .onComplete { _ in
            self.refreshControl?.endRefreshing()
        }
    }
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    if let selectedDeliverable = collection?[indexPath.row] {
      switch parent {
      case is AgendaItem:
        let deliverableViewController = R.storyboard.deliverable.initialViewController()!
        deliverableViewController.deliverable = selectedDeliverable

        self.navigationController?.pushViewController(deliverableViewController, animated: true)
      case is Conversation:
        let deliverableViewController = R.storyboard.deliverable.initialViewController()!
        deliverableViewController.deliverable = selectedDeliverable

        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromTop
        self.navigationController?.view.layer.addAnimation(transition, forKey: nil)

        self.navigationController?.pushViewController(deliverableViewController, animated: false)
      default:
        let conversationController = R.storyboard.conversation.initialViewController()!
        conversationController.conversation = storageManager!.conversations[getConversationId(selectedDeliverable)]
        conversationController.openItem = selectedDeliverable

        presentViewController(conversationController, animated:true, completion: nil)
      }
    } else {
      fatalError()
    }
  }
}
