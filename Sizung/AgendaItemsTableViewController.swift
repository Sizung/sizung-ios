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
  
  let filteredCollection: CollectionProperty <[AgendaItem]> = CollectionProperty([])
  let sortedAndFilteredCollection: CollectionProperty <[AgendaItem]> = CollectionProperty([])
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.refreshControl?.addTarget(self, action: #selector(self.updateData), forControlEvents: UIControlEvents.ValueChanged)
    
    self.initData()
  }
  
  func initData(){
    
    let storageManager = StorageManager.sharedInstance
    
    storageManager.isLoading.observeNext { isLoading in
      if isLoading {
        self.refreshControl?.beginRefreshing()
      } else {
        self.refreshControl?.endRefreshing()
      }
      }.disposeIn(rBag)
    
    storageManager.agendaItems
      .filter({ agendaItem in
        if let conversationId = self.conversation?.id {
          return agendaItem.conversation.id == conversationId
        } else {
          return true
        }
      }).bindTo(filteredCollection)
    
    //    sort by created at date
    filteredCollection
      .sort({ left, right in
        return left.created_at.compare(right.created_at) == NSComparisonResult.OrderedDescending
      }).bindTo(sortedAndFilteredCollection)
    
    sortedAndFilteredCollection.bindTo(self.tableView) { indexPath, agendaItems, tableView in
      let cell = tableView.dequeueReusableCellWithIdentifier("AgendaItemTableViewCell", forIndexPath: indexPath) as! AgendaItemTableViewCell
      let agendaItem = agendaItems[indexPath.row]
      cell.titleLabel.text = agendaItem.title
      
      cell.conversationLabel.text = ""
      
      if let conversationTitle = storageManager.getConversation(agendaItem.conversation.id)?.title {
        cell.conversationLabel.text = "@\(conversationTitle)"
      }
      
      
      // TODO: Real unread status
      cell.unreadStatusView.alpha = arc4random_uniform(2) == 0 ? 1:0
      
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
