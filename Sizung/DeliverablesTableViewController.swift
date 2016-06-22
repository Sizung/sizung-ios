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
  
  var conversation: Conversation?
  
  var userId: String?
  var filter: Filter = .Mine
  
  enum Filter {
    case Mine
    case All
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.refreshControl?.addTarget(self, action: #selector(self.updateData), forControlEvents: UIControlEvents.ValueChanged)
    self.tableView.registerNib(R.nib.deliverableTableViewCell(), forCellReuseIdentifier: R.nib.deliverableTableViewCell.identifier)
    
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
    StorageManager.sharedInstance.deliverables.filter { deliverable in
      
      if self.conversation != nil && self.conversation!.id != deliverable.conversation.id {
        return false
      }
      
      if self.filter == .Mine {
        return deliverable.owner.id == self.userId
      } else {
        return true
      }
      }.bindTo(filteredCollection)
  }
  
  func initData(){
    
    StorageManager.sharedInstance.isLoading.observeNext { isLoading in
      if isLoading {
        self.refreshControl?.beginRefreshing()
      } else {
        self.refreshControl?.endRefreshing()
      }
      }.disposeIn(rBag)
    
    sortedAndFilteredCollection.observeNext { _ in
        self.tableView.tableFooterView?.hidden = self.sortedAndFilteredCollection.count >= 0
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
    
    filterCollection()
    
//    sort
    filteredCollection
      .sort({ left, right in
        //        sort completed to bottom of list
        if left.isCompleted() && !right.isCompleted() {
          return false
        } else if !left.isCompleted() && right.isCompleted() {
          return true
          //        sort items with due date on top
        } else if left.due_on != nil && right.due_on == nil {
          return true
        } else if left.due_on == nil && right.due_on != nil {
          return false
          //        sort grouped items by sort_date
        } else {
          return left.sort_date.isEarlierThan(right.sort_date)
        }
      }).bindTo(sortedAndFilteredCollection)
    
    sortedAndFilteredCollection.bindTo(self.tableView) { indexPath, deliverables, tableView in
      let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.deliverableTableViewCell.identifier, forIndexPath: indexPath) as! DeliverableTableViewCell
      let deliverable = deliverables[indexPath.row]
      cell.titleLabel.text = deliverable.title
      
      cell.conversationLabel.text = StorageManager.sharedInstance.getConversation(deliverable.conversation.id)?.title
      
      if deliverable.due_on != nil && !deliverable.isCompleted() {
        cell.statusLabel.text = DueDateHelper.getDueDateString(deliverable.due_on!)
      } else {
        cell.statusLabel.text = deliverable.getStatus()
      }
      
      var statusColor = UIColor(red:0.88, green:0.67, blue:0.71, alpha:1.0)
      var textStatusColor = UIColor.darkTextColor()
      
      if deliverable.isCompleted() {
        statusColor = UIColor(red:0.33, green:0.75, blue:0.59, alpha:1.0)
        textStatusColor = statusColor
      } else if deliverable.due_on != nil && deliverable.due_on?.daysAgo() >= 0 {
        //overdue or today
        statusColor = UIColor(red:0.98, green:0.40, blue:0.38, alpha:1.0)
        textStatusColor = statusColor
      }
      
      cell.statusView.backgroundColor = statusColor
      cell.statusView.layer.borderColor = statusColor.CGColor
      cell.statusLabel.textColor = textStatusColor
      
      let hasUnseenObjects = StorageManager.sharedInstance.unseenObjects.collection.contains { obj in
        return obj.deliverable?.id == deliverable.id
      }
      
      if !deliverable.isCompleted() && !hasUnseenObjects {
        cell.statusView.backgroundColor = UIColor.clearColor()
      }
      cell.unreadStatusView.alpha = hasUnseenObjects ? 1 : 0
      
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
    
    let selectedDeliverable = sortedAndFilteredCollection[indexPath.row]
    
    let deliverableViewController = R.storyboard.deliverable.initialViewController()!
    deliverableViewController.deliverable = selectedDeliverable
    
    self.showViewController(deliverableViewController, sender: self)
  }
}
/*
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
 */
