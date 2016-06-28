//
//  OrganizationsTableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 21/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import ReactiveKit
import ReactiveUIKit

class OrganizationsTableViewController: UITableViewController {
  
  let organizations: CollectionProperty <[Organization]> = CollectionProperty([])
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.refreshControl?.addTarget(self, action: #selector(self.updateData), forControlEvents: UIControlEvents.ValueChanged)
    self.tableView.registerNib(R.nib.organizationTableViewCell(), forCellReuseIdentifier: R.nib.organizationTableViewCell.identifier)
    
    self.initData()
  }
  
  func initData(){
    organizations.bindTo(self.tableView) { indexPath, organizations, tableView in
      let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.organizationTableViewCell.identifier, forIndexPath: indexPath) as! OrganizationTableViewCell
      let organization = organizations[indexPath.row]
      cell.nameLabel.text = organization.name
      
      let hasUnseenObject = StorageManager.sharedInstance.unseenObjects.collection.contains { obj in
        return obj.organizationId == organization.id
      }
      
      cell.unreadStatusView.alpha = hasUnseenObject ? 1 : 0
      return cell
    }
  }
  
  override func viewDidAppear(animated: Bool) {
    updateData()
  }
  
  func updateData(){
    self.refreshControl?.beginRefreshing()
    StorageManager.sharedInstance.listOrganizations()
      .onSuccess { organizations in
        self.organizations.replace(organizations, performDiff: true)
      }.onFailure { error in
        let message = "\(error)"
        Error.log(message)
      }.onComplete { _ in
        self.refreshControl?.endRefreshing()
    }
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let selectedOrganization = organizations[indexPath.row]
    
    // reset storage
    StorageManager.sharedInstance.reset()
    
    KeychainWrapper.setString(selectedOrganization.id!, forKey: Configuration.Settings.SELECTED_ORGANIZATION)
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
  }
}
