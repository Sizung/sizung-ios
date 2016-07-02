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
    
    self.refreshControl?.addTarget(self, action: #selector(self.updateData), forControlEvents: UIControlEvents.ValueChanged)
    self.tableView.registerNib(R.nib.agendaItemTableViewCell(), forCellReuseIdentifier: R.nib.agendaItemTableViewCell.identifier)
    
    userId = AuthToken(data: KeychainWrapper.stringForKey(Configuration.Settings.AUTH_TOKEN)).getUserId()
    
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
  
  func updateCollection(){
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        
        self.storageManager = storageManager
        
        self.collection = storageManager.agendaItems.collection
          .filter { agendaItem in
            if let conversationId = self.conversation?.id {
              return agendaItem.conversationId == conversationId
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
            return left.created_at.compare(right.created_at) == NSComparisonResult.OrderedDescending
          }

        
        self.tableView.tableFooterView?.hidden = self.collection!.count > 0
        
        self.tableView.reloadData()
    }
    
    
  }
  
  func initData(){
    
    // listen to unseenObject changes
    StorageManager.sharedInstance.unseenObjects.observeNext { _ in
      self.tableView.reloadData()
      }.disposeIn(rBag)
    
    // listen to deliverable changes
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        storageManager.agendaItems.observeNext {_ in
          self.tableView.reloadData()
          }.disposeIn(self.rBag)
    }
    
    updateCollection()
  }
  
  override func viewDidAppear(animated: Bool) {
    if self.collection == nil || self.collection?.count == 0 {
      self.updateData()
    }
  }
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.collection?.count ?? 0
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.agendaItemTableViewCell.identifier, forIndexPath: indexPath) as! AgendaItemTableViewCell
    let agendaItem = self.collection![indexPath.row]
    cell.titleLabel.text = agendaItem.title
    
    cell.conversationLabel.text = ""
    
    if let conversationTitle = storageManager?.conversations[agendaItem.conversationId]?.title {
      cell.conversationLabel.text = "@\(conversationTitle)"
    }
    
    let hasUnseenObject = StorageManager.sharedInstance.unseenObjects.collection.contains { obj in
      return obj.agendaItemId == agendaItem.id
    }
    
    cell.unreadStatusView.alpha = hasUnseenObject ? 1 : 0
    
    if let user = storageManager?.users[agendaItem.ownerId] {
      cell.authorImageView.user = user
    }
    
    return cell
  }
  
  func updateData(){
    self.refreshControl?.beginRefreshing()
    StorageManager.storageForSelectedOrganization()
      .onSuccess{ storageManager in
        storageManager.listAgendaItems()
          .onSuccess { _ in
            self.refreshControl?.endRefreshing()
        }
    }
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    let selectedAgendaItem = self.collection![indexPath.row]
    
    let agendaItemViewController = UIStoryboard(name: "AgendaItem", bundle: nil).instantiateInitialViewController() as! AgendaItemViewController
    agendaItemViewController.agendaItem = selectedAgendaItem
    
    self.showViewController(agendaItemViewController, sender: self)
  }
}
