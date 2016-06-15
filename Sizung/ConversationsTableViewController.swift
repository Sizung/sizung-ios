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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.refreshControl?.addTarget(self, action: #selector(self.updateData), forControlEvents: UIControlEvents.ValueChanged)
    self.tableView.registerNib(R.nib.conversationTableViewCell)
    
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
    
    storageManager.conversations.bindTo(self.tableView) { indexPath, conversations, tableView in
      let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.conversationTableViewCell.identifier, forIndexPath: indexPath) as! ConversationTableViewCell
      let conversation = conversations[indexPath.row]
      cell.nameLabel.text = conversation.title
      
      let activeUsersCount = conversation.members.reduce(0, combine: {sum, member in
        if let user = storageManager.getUser(member.id) {
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
        if let user = storageManager.getUser(member.id) {
          let imageWidth = cell.activeImageViewsContainerView.frame.height
          
          let gravatar = Gravatar(emailAddress: user.email, defaultImage: .Identicon)
          let imageView = UIImageView()
          imageView.frame = CGRect(x: currentPos, y: 0, width: imageWidth, height: imageWidth)
          cell.activeImageViewsContainerView.addSubview(imageView)
          cell.configureImageViewWithURLString(imageView, URLString: gravatar.URL(size: cell.bounds.width).URLString)
          
          currentPos += imageWidth
        }
      }
      
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
      
      //      fetch organizations
      StorageManager.sharedInstance.updateOrganizations()
    } else {
      print("no organization selected in \(self)")
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
        let selectedConversation = StorageManager.sharedInstance.conversations[indexPath.row]
        conversationViewController.conversation = selectedConversation
      }
    }
  }
}
