//
//  AgendaItemsTableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 25/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import ReactiveKit
import AKSegmentedControl

class AgendaItemsTableViewController: UITableViewController {

  var conversation: Conversation?
  var filter: Filter = .Mine

  var userId: String?

  var storageManager: OrganizationStorageManager?

  @IBOutlet weak var segmentedControl: AKSegmentedControl!

  var emptyView: UIView?

  enum Filter {
    case Mine
    case All
  }

  var collection: [AgendaItem]?

  override func viewDidLoad() {
    super.viewDidLoad()

    self.refreshControl?.addTarget(
      self,
      action: #selector(self.updateData),
      forControlEvents: UIControlEvents.ValueChanged
    )
    self.tableView.registerNib(
      R.nib.agendaItemTableViewCell(),
      forCellReuseIdentifier: R.nib.agendaItemTableViewCell.identifier
    )

    self.emptyView = self.tableView.tableFooterView
    self.tableView.tableFooterView = nil

    userId = AuthToken(
      data: Configuration.getSessionToken()).getUserId()

    self.initData()
    self.initSegmentedControl()
  }

  func initSegmentedControl() {
    let allButton = UIButton()
    allButton.setBackgroundImage(R.image.agenda_filter_all(), forState: .Normal)
    allButton.setBackgroundImage(R.image.agenda_filter_all_selected(), forState: .Selected)
    allButton.titleLabel?.font = R.font.brandonGrotesqueMedium(size: 15)
    allButton.setTitleColor(Color.AGENDAITEM, forState: .Normal)
    allButton.setTitleColor(UIColor.whiteColor(), forState: .Selected)
    allButton.setTitle("All", forState: .Normal)

    let myButton = UIButton()
    myButton.setBackgroundImage(R.image.agenda_filter_mine(), forState: .Normal)
    myButton.setBackgroundImage(R.image.agenda_filter_mine_selected(), forState: .Selected)
    myButton.titleLabel?.font = R.font.brandonGrotesqueMedium(size: 15)
    myButton.setTitleColor(Color.AGENDAITEM, forState: .Normal)
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

        let filteredCollection = storageManager.agendaItems.collection
          .filter { agendaItem in

            if self.conversation != nil && self.conversation!.id != agendaItem.conversationId {
              return false
            }

            if agendaItem.archived == true {
              return false
            }

            if self.filter == .Mine {
              return agendaItem.ownerId == self.userId
            } else {
              return true
            }
        }

        // first, handle open, numbered items
        self.collection = filteredCollection.filter { $0.isOpen() && $0.isNumbered() }
          .sort { left, right in
            return left.number < right.number
        }

        // second, handle open, unnumbered items
        self.collection?.appendContentsOf(filteredCollection.filter { $0.isOpen() && !$0.isNumbered() }
          .sort { left, right in
            return left.updatedAt.compare(right.updatedAt) == NSComparisonResult.OrderedDescending
        })

        // third, handle resolved items
        self.collection?.appendContentsOf(filteredCollection.filter { $0.isResolved() }
          .sort { left, right in
            return left.updatedAt.compare(right.updatedAt) == NSComparisonResult.OrderedDescending
          })

        if self.collection!.count > 0 {
          self.tableView.backgroundView = nil
        } else {
          self.tableView.backgroundView = self.emptyView
        }

        self.tableView.reloadData()

        // hide filter after launch and after selection
        self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.tableHeaderView!.frame.height), animated: true)
    }
  }

  func initData() {

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.storageManager = storageManager

        // listen to unseenObject changes
        storageManager.unseenObjects.observeNext { _ in
          self.tableView.reloadData()
          }.disposeIn(self.rBag)

        // listen to deliverable changes
        storageManager.agendaItems.observeNext {_ in
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

  override func tableView(
    tableView: UITableView,
    cellForRowAtIndexPath indexPath: NSIndexPath)
    -> UITableViewCell {
      if let cell = tableView.dequeueReusableCellWithIdentifier(
        R.nib.agendaItemTableViewCell.identifier,
        forIndexPath: indexPath
        ) as? AgendaItemTableViewCell {
        let agendaItem = self.collection![indexPath.row]
        cell.titleLabel.text = agendaItem.title

        cell.conversationLabel.text = ""

        // only show if not filtered by conversation - redundant
        if conversation == nil {
          if let conversationTitle = storageManager?.conversations[agendaItem.conversationId]?.title {
            cell.conversationLabel.text = conversationTitle
          }
        }

        let unseenObjects = self.storageManager!.unseenObjects.collection

        let hasUnseenObject = unseenObjects.contains { obj in
          return obj.agendaItemId == agendaItem.id
        }

        cell.unreadStatusView.alpha = hasUnseenObject ? 1 : 0

        if let user = storageManager?.users[agendaItem.ownerId] {
          cell.authorImageView.user = user
        }

        let unresolvedActionItemListCount = self.storageManager!.deliverables.collection.reduce(0) { prev, deliverable in
          if deliverable.parentId == agendaItem.id && !deliverable.isCompleted() {
            return prev + 1
          } else {
            return prev
          }
        }

        cell.agendaStatusLabel.backgroundColor = UIColor.whiteColor()
        cell.agendaStatusLabel.layer.borderUIColor = Color.AGENDAITEM
        cell.agendaStatusLabel.text = ""

        if unresolvedActionItemListCount > 0 {
          cell.agendaStatusLabel.layer.borderUIColor = Color.ACTION
          cell.agendaStatusLabel.text = "\(unresolvedActionItemListCount)"
        } else if agendaItem.isResolved() {
          cell.agendaStatusLabel.backgroundColor = Color.AGENDAITEM
        }


        return cell
      } else {
        fatalError("Unknown cell type in \(type(of: self))")
      }
  }

  func updateData() {
    self.refreshControl?.beginRefreshing()
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        storageManager.listAgendaItems()
          .onSuccess { _ in
            self.refreshControl?.endRefreshing()
        }
    }
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    let selectedAgendaItem = self.collection![indexPath.row]

    if self.navigationController?.viewControllers.first is ConversationContentViewController {
      let agendaItemViewController = R.storyboard.agendaItem.initialViewController()!
      agendaItemViewController.agendaItem = selectedAgendaItem

      let transition = CATransition()
      transition.duration = 0.3
      transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
      transition.type = kCATransitionPush
      transition.subtype = kCATransitionFromTop
      self.navigationController?.view.layer.addAnimation(transition, forKey: nil)

      self.navigationController?.pushViewController(agendaItemViewController, animated: false)
    } else {

      let conversationController = R.storyboard.conversation.initialViewController()!
      conversationController.conversation = storageManager!.conversations[selectedAgendaItem.conversationId]
      conversationController.openItem = selectedAgendaItem

      presentViewController(conversationController, animated:true, completion: nil)
    }

  }
}
