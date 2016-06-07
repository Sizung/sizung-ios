//
//  AgendaItemsTableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 25/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class AgendaItemsTableViewController: UITableViewController {
  
  var conversation: Conversation?
  
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
    
    storageManager.agendaItems.filter { agendaItem in
      if let conversationId = self.conversation?.id {
        return agendaItem.conversation.id == conversationId
      } else {
        return true
      }
    }.bindTo(self.tableView) { indexPath, agendaItems, tableView in
      let cell = tableView.dequeueReusableCellWithIdentifier("AgendaItemTableViewCell", forIndexPath: indexPath) as! AgendaItemTableViewCell
      let agendaItem = agendaItems[indexPath.row]
      cell.titleLabel.text = agendaItem.title
      cell.conversationLabel.text = agendaItem.conversation.title
      
      
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
  
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showTimeline" {
      let timelineTableViewController = segue.destinationViewController as! TimelineTableViewController
      
      // Get the cell that generated this segue.
      if let selectedCell = sender as? SizungTableViewCell {
        let indexPath = tableView.indexPathForCell(selectedCell)!
        let selectedConversation = StorageManager.sharedInstance.conversations[indexPath.row]
        timelineTableViewController.conversation = selectedConversation
        timelineTableViewController.navigationItem.title = selectedConversation.title
      }
    }
  }

}