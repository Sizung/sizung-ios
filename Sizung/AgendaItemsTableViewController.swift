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

class AgendaItemsTableViewController: UITableViewController {

  var conversation: Conversation?
  var filter: Filter = .Mine

  var userId: String?

  var storageManager: OrganizationStorageManager?

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

    userId = AuthToken(
      data: Configuration.getAuthToken()).getUserId()

    self.initData()
  }

  @IBAction func filterValueChanged(sender: UISegmentedControl) {
    switch sender.selectedSegmentIndex {
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

        self.storageManager = storageManager

        self.collection = storageManager.agendaItems.collection
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


        //    sort by created at date
        self.collection!
          .sortInPlace { left, right in
            return left.createdAt.compare(right.createdAt) == NSComparisonResult.OrderedDescending
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

        if let conversationTitle = storageManager?.conversations[agendaItem.conversationId]?.title {
          cell.conversationLabel.text = conversationTitle
        }

        let unseenObjects = self.storageManager!.unseenObjects.collection

        let hasUnseenObject = unseenObjects.contains { obj in
          return obj.agendaItemId == agendaItem.id
        }

        cell.unreadStatusView.alpha = hasUnseenObject ? 1 : 0

        if let user = storageManager?.users[agendaItem.ownerId] {
          cell.authorImageView.user = user
        }

        return cell
      } else {
        fatalError("Unknown cell type in \(self.dynamicType)")
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

    if let navController = self.navigationController {
      let agendaItemViewController = R.storyboard.agendaItem.initialViewController()!
      agendaItemViewController.agendaItem = selectedAgendaItem

      navController.pushViewController(agendaItemViewController, animated: true)
    } else {
      let conversationController = R.storyboard.conversation.initialViewController()!
      conversationController.conversation = storageManager!.conversations[selectedAgendaItem.conversationId]
      conversationController.openItem = selectedAgendaItem
      showViewController(conversationController, sender: self)
    }
  }
}
