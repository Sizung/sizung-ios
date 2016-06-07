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

class DeliverablesTableViewController: UITableViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.refreshControl?.addTarget(self, action: #selector(self.updateData), forControlEvents: UIControlEvents.ValueChanged)
    
    self.initData()
  }
  
  func bindData() {
    print("no usage")
  }
  
  func initData(){
    
    StorageManager.sharedInstance.isLoading.observeNext { isLoading in
      if isLoading {
        self.refreshControl?.beginRefreshing()
      } else {
        self.refreshControl?.endRefreshing()
      }
      }.disposeIn(rBag)
    
    bindData()
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

class UserDeliverablesTableViewController: DeliverablesTableViewController {
  override func bindData() {
    
    let token = AuthToken(data: KeychainWrapper.stringForKey(Configuration.Settings.AUTH_TOKEN))
    let userId = token.getUserId()
    
    StorageManager.sharedInstance.organizationDeliverables.filter { deliverable in
      deliverable.owner.id == userId!
      }.bindTo(self.tableView) { indexPath, deliverables, tableView in
        let cell = tableView.dequeueReusableCellWithIdentifier("DeliverableTableViewCell", forIndexPath: indexPath) as! DeliverableTableViewCell
        let deliverable = deliverables[indexPath.row]
        cell.titleLabel.text = deliverable.title
        cell.conversationLabel.text = deliverable.conversation?.title
        cell.statusLabel.text = deliverable.status
        
        // TODO: Real unread status
        cell.unreadStatusView.alpha = arc4random_uniform(2) == 0 ? 1:0
        
        return cell
    }
    
  }
}

class ConversationDeliverablesTableViewController: DeliverablesTableViewController {
  
  var conversation: Conversation!
  
  override func bindData() {
    
    StorageManager.sharedInstance.conversationDeliverables.filter { deliverable in
      deliverable.conversation.id == self.conversation.id
      }.bindTo(self.tableView) { indexPath, deliverables, tableView in
        let cell = tableView.dequeueReusableCellWithIdentifier("DeliverableTableViewCell", forIndexPath: indexPath) as! DeliverableTableViewCell
        let deliverable = deliverables[indexPath.row]
        cell.titleLabel.text = deliverable.title
        cell.conversationLabel.text = deliverable.conversation?.title
        cell.statusLabel.text = deliverable.status
        
        // TODO: Real unread status
        cell.unreadStatusView.alpha = arc4random_uniform(2) == 0 ? 1:0
        return cell
    }
    
  }
}

