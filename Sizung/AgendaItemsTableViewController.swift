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
  
  enum Filter {
    case Mine
    case All
  }
  
  let conversationFilteredCollection: CollectionProperty <[AgendaItem]> = CollectionProperty([])
  let filteredCollection: CollectionProperty <[AgendaItem]> = CollectionProperty([])
  let sortedAndFilteredCollection: CollectionProperty <[AgendaItem]> = CollectionProperty([])
  
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
    
    filterCollection()
  }
  
  func filterCollection(){
    conversationFilteredCollection.filter { agendaItem in
      if self.filter == .Mine {
        return agendaItem.owner.id == self.userId
      } else {
        return true
      }
    }.bindTo(filteredCollection)
  }
  
  func initData(){
    
    sortedAndFilteredCollection.observeNext { _ in
      self.tableView.tableFooterView?.hidden = self.sortedAndFilteredCollection.count > 0
    }.disposeIn(rBag)
  
    let storageManager = StorageManager.sharedInstance
    
    storageManager.isLoading.observeNext { isLoading in
      if isLoading {
        self.refreshControl?.beginRefreshing()
      } else {
        self.refreshControl?.endRefreshing()
      }
      }.disposeIn(rBag)
    
    // listen to unseenObject changes
    storageManager.unseenObjects.observeNext { _ in
      self.tableView.reloadData()
      }.disposeIn(rBag)
    
    storageManager.agendaItems
      .filter({ agendaItem in
        if let conversationId = self.conversation?.id {
          return agendaItem.conversation.id == conversationId
        } else {
          return true
        }
      }).bindTo(conversationFilteredCollection)
    
    filterCollection()
    
    //    sort by created at date
    filteredCollection
      .sort({ left, right in
        return left.created_at.compare(right.created_at) == NSComparisonResult.OrderedDescending
      }).bindTo(sortedAndFilteredCollection)
    
    sortedAndFilteredCollection.bindTo(self.tableView) { indexPath, agendaItems, tableView in
      let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.agendaItemTableViewCell.identifier, forIndexPath: indexPath) as! AgendaItemTableViewCell
      let agendaItem = agendaItems[indexPath.row]
      cell.titleLabel.text = agendaItem.title
      
      cell.conversationLabel.text = ""
      
      if let conversationTitle = storageManager.getConversation(agendaItem.conversation.id)?.title {
        cell.conversationLabel.text = "@\(conversationTitle)"
      }
      
      let hasUnseenObject = StorageManager.sharedInstance.unseenObjects.collection.contains { obj in
        return obj.agendaItem?.id == agendaItem.id
      }
      
      cell.unreadStatusView.alpha = hasUnseenObject ? 1 : 0
      
      return cell
    }
  }
  
  override func viewDidAppear(animated: Bool) {
    if !StorageManager.sharedInstance.isInitialized {
      self.updateData()
    }
  }
  
  func updateData(){
    if let organizationId = KeychainWrapper.stringForKey(Configuration.Settings.SELECTED_ORGANIZATION) {
      StorageManager.sharedInstance.updateOrganization(organizationId)
    } else {
      fatalError("no organization selected in \(self)")
    }
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    let selectedAgendaItem = sortedAndFilteredCollection[indexPath.row]
    
    let agendaItemViewController = UIStoryboard(name: "AgendaItem", bundle: nil).instantiateInitialViewController() as! AgendaItemViewController
    agendaItemViewController.agendaItem = selectedAgendaItem
    
    self.showViewController(agendaItemViewController, sender: self)
  }
}
