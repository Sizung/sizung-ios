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

class DeliverablesTableViewController: UITableViewController {
  
  let sortedCollection: CollectionProperty <[Deliverable]> = CollectionProperty([])
  let filteredCollection: CollectionProperty <[Deliverable]> = CollectionProperty([])
  
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
  
  var userId: String!
  
  override func bindData() {
    
    self.tableView.registerNib(UINib.init(nibName: "DeliverableTableViewCell", bundle: nil), forCellReuseIdentifier: "DeliverableTableViewCell")
    
    StorageManager.sharedInstance.deliverables
      .filter({ deliverable in
        return deliverable.assignee.id == self.userId
      })
      .bindTo(filteredCollection)
    
    //    sort by due date
    filteredCollection.sort({ left, right in
      if right.due_on == nil {
        return true
      } else {
        return left.due_on?.compare(right.due_on!) == NSComparisonResult.OrderedDescending
      }
    })
      .bindTo(sortedCollection)
    
    sortedCollection.bindTo(self.tableView) { indexPath, deliverables, tableView in
      let cell = tableView.dequeueReusableCellWithIdentifier("DeliverableTableViewCell", forIndexPath: indexPath) as! DeliverableTableViewCell
      let deliverable = deliverables[indexPath.row]
      cell.titleLabel.text = deliverable.title
      
      switch deliverable.parent {
      case let conversation as Conversation:
        cell.conversationLabel.text = StorageManager.sharedInstance.getConversation(conversation.id)?.title
      case let agendaItem as AgendaItem:
        cell.conversationLabel.text = StorageManager.sharedInstance.getAgendaItem(agendaItem.id)?.title
      default:
        cell.conversationLabel.text = nil
      }
      
      if let due_date = deliverable.due_on {
        cell.statusLabel.text = due_date.timeAgoSinceNow()
      } else {
        cell.statusLabel.text = deliverable.status
      }
      
      // TODO: Real unread status
      cell.unreadStatusView.alpha = arc4random_uniform(2) == 0 ? 1:0
      
      return cell
    }
    
  }
}

class ConversationDeliverablesTableViewController: DeliverablesTableViewController {
  
  var conversation: Conversation!
  
  override func bindData() {
    
    self.tableView.registerNib(UINib.init(nibName: "DeliverableTableViewCell", bundle: nil), forCellReuseIdentifier: "DeliverableTableViewCell")
    
    StorageManager.sharedInstance.deliverables.filter { deliverable in
      deliverable.parent.id == self.conversation?.id
      }.bindTo(self.tableView) { indexPath, deliverables, tableView in
        let cell = tableView.dequeueReusableCellWithIdentifier("DeliverableTableViewCell", forIndexPath: indexPath) as! DeliverableTableViewCell
        let deliverable = deliverables[indexPath.row]
        cell.titleLabel.text = deliverable.title
        
        if let due_date = deliverable.due_on {
          cell.statusLabel.text = due_date.timeAgoSinceNow()
        } else {
          cell.statusLabel.text = deliverable.status
        }
        
        switch deliverable.parent {
        case let conversation as Conversation:
          cell.conversationLabel.text = StorageManager.sharedInstance.getConversation(conversation.id)?.title
        case let agendaItem as AgendaItem:
          cell.conversationLabel.text = StorageManager.sharedInstance.getAgendaItem(agendaItem.id)?.title
        default:
          cell.conversationLabel.text = nil
        }
        
        
        // TODO: Real unread status
        cell.unreadStatusView.alpha = arc4random_uniform(2) == 0 ? 1:0
        return cell
    }
    
  }
}

