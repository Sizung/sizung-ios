//
//  ConversationsTableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 21/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import ReactiveKit
import ReactiveUIKit
import SwiftKeychainWrapper

class ConversationsTableViewController: UITableViewController {
  
  let sortedCollection: CollectionProperty <[Conversation]> = CollectionProperty([])
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.refreshControl?.addTarget(self, action: #selector(self.updateData), forControlEvents: UIControlEvents.ValueChanged)
    self.tableView.registerNib(R.nib.conversationTableViewCell)
    
    self.initData()
  }
  
  func initData(){
    
    // listen to unseenObject changes
    StorageManager.sharedInstance.unseenObjects.observeNext { _ in
      self.tableView.reloadData()
      }.disposeIn(rBag)
    
    StorageManager.storageForSelectedOrganization().onSuccess { storageManager in
      storageManager.conversations.sort { left, right in
        return left.title.compare(right.title) == .OrderedAscending
        }.bindTo(self.sortedCollection)
      
      
      self.sortedCollection.bindTo(self.tableView) { indexPath, conversations, tableView in
        let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.conversationTableViewCell.identifier, forIndexPath: indexPath) as! ConversationTableViewCell
        let conversation = conversations[indexPath.row]
        cell.nameLabel.text = conversation.title
        
        let activeUsersCount = conversation.members.reduce(0, combine: {sum, member in
          if let user = storageManager.users[member.id] {
            return sum + (user.isActive() ? 1 : 0)
          } else {
            return sum
          }
        })
        
        
        cell.activeCountLabel.text = "\(activeUsersCount) active"
        // clear containerview
        cell.activeImageViewsContainerView.subviews.forEach({$0.removeFromSuperview()})
        
        var currentPos: CGFloat = 0
        
        conversation.members.forEach { member in
          if let user = storageManager.users[member.id] {
            
            guard user.isActive() else {
              return
            }
            
            let imageWidth = cell.activeImageViewsContainerView.frame.height
            
            let imageView = AvatarImageView()
            imageView.frame = CGRect(x: currentPos, y: 0, width: imageWidth, height: imageWidth)
            cell.activeImageViewsContainerView.addSubview(imageView)
            imageView.user = user
            
            currentPos += imageWidth
          }
        }
        
        let hasUnseenObject = StorageManager.sharedInstance.unseenObjects.collection.contains { obj in
          return obj.conversationId == conversation.id
        }
        
        cell.unreadStatusView.alpha = hasUnseenObject ? 1 : 0
        
        return cell
      }
    }
  }
  
  func updateData(){
    
    self.refreshControl?.beginRefreshing()
    
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        storageManager.listConversations()
          .onComplete { _ in
            self.refreshControl?.endRefreshing()
        }
    }
  }
  
  // MARK: - Navigation
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let cell = tableView.cellForRowAtIndexPath(indexPath)
    self.performSegueWithIdentifier("showConversation", sender: cell)
  }
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showConversation" {
      let conversationViewController = segue.destinationViewController as! ConversationViewController
      
      // Get the cell that generated this segue.
      if let selectedCell = sender as? UITableViewCell {
        let indexPath = tableView.indexPathForCell(selectedCell)!
        let selectedConversation = sortedCollection[indexPath.row]
        conversationViewController.conversation = selectedConversation
      }
    }
  }
}
