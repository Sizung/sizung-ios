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
  
  let filteredCollection: CollectionProperty <[Deliverable]> = CollectionProperty([])
  let sortedAndFilteredCollection: CollectionProperty <[Deliverable]> = CollectionProperty([])
  
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
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    let selectedDeliverable = sortedAndFilteredCollection[indexPath.row]
    
    let deliverableViewController = R.storyboard.deliverable.initialViewController()!
    deliverableViewController.deliverable = selectedDeliverable
    
    self.showViewController(deliverableViewController, sender: self)
  }
}

class UserDeliverablesTableViewController: DeliverablesTableViewController {
  
  var userId: String!
  
  override func bindData() {
    
    self.tableView.registerNib(R.nib.deliverableTableViewCell(), forCellReuseIdentifier: R.nib.deliverableTableViewCell.identifier)
    
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
      .bindTo(sortedAndFilteredCollection)
    
    sortedAndFilteredCollection.bindTo(self.tableView) { indexPath, deliverables, tableView in
      let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.deliverableTableViewCell.identifier, forIndexPath: indexPath) as! DeliverableTableViewCell
      let deliverable = deliverables[indexPath.row]
      cell.titleLabel.text = deliverable.title
      
      //      switch deliverable.parent {
      //      case let conversation as Conversation:
      //        cell.conversationLabel.text = StorageManager.sharedInstance.getConversation(conversation.id)?.title
      //      case let agendaItem as AgendaItem:
      //        cell.conversationLabel.text = StorageManager.sharedInstance.getAgendaItem(agendaItem.id)?.title
      //      default:
      //        cell.conversationLabel.text = nil
      //      }
      
      cell.conversationLabel.text = StorageManager.sharedInstance.getConversation(deliverable.conversation.id)?.title
      
      if deliverable.due_on != nil && !deliverable.isCompleted() {
        cell.statusLabel.text = DueDateHelper.getDueDateString(deliverable.due_on!)
      } else {
        cell.statusLabel.text = deliverable.getStatus()
      }
      
      let hasUnseenObject = StorageManager.sharedInstance.unseenObjects.collection.contains { obj in
        return obj.deliverable?.id == deliverable.id
      }
      
      cell.unreadStatusView.alpha = hasUnseenObject ? 1 : 0
      
      return cell
    }
    
  }
}

class ConversationDeliverablesTableViewController: DeliverablesTableViewController {
  
  var conversation: Conversation!
  
  override func bindData() {
    
    self.tableView.registerNib(UINib.init(nibName: "DeliverableTableViewCell", bundle: nil), forCellReuseIdentifier: "DeliverableTableViewCell")
    
    StorageManager.sharedInstance.deliverables
      .filter({ deliverable in
        return deliverable.conversation.id == self.conversation.id
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
      .bindTo(sortedAndFilteredCollection)
    
    sortedAndFilteredCollection.bindTo(self.tableView) { indexPath, deliverables, tableView in
      let cell = tableView.dequeueReusableCellWithIdentifier("DeliverableTableViewCell", forIndexPath: indexPath) as! DeliverableTableViewCell
      let deliverable = deliverables[indexPath.row]
      cell.titleLabel.text = deliverable.title
      
      if let due_date = deliverable.due_on {
        cell.statusLabel.text = due_date.timeAgoSinceNow()
      } else {
        cell.statusLabel.text = deliverable.status
      }
      
      cell.conversationLabel.text = StorageManager.sharedInstance.getConversation(deliverable.conversation.id)?.title
      
      // TODO: Real unread status
      cell.unreadStatusView.alpha = arc4random_uniform(2) == 0 ? 1:0
      return cell
    }
    
  }
}

