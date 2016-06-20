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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.refreshControl?.addTarget(self, action: #selector(self.updateData), forControlEvents: UIControlEvents.ValueChanged)
    self.tableView.registerNib(R.nib.organizationTableViewCell(), forCellReuseIdentifier: R.nib.organizationTableViewCell.identifier)
    
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
    
    storageManager.organizations.bindTo(self.tableView) { indexPath, organizations, tableView in
      let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.organizationTableViewCell.identifier, forIndexPath: indexPath) as! OrganizationTableViewCell
      let organization = organizations[indexPath.row]
      cell.nameLabel.text = organization.name
      cell.unreadStatusView.alpha = StorageManager.sharedInstance.unseenObjects.contains(organization) ? 1 : 0
      return cell
    }
  }
  
  override func viewDidAppear(animated: Bool) {
    updateData()
  }
  
  func updateData(){
    StorageManager.sharedInstance.updateOrganizations()
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let selectedOrganization = StorageManager.sharedInstance.organizations[indexPath.row]
    
    // reset storage
    StorageManager.sharedInstance.reset()
    
    KeychainWrapper.setString(selectedOrganization.id!, forKey: Configuration.Settings.SELECTED_ORGANIZATION)
    self.dismissViewControllerAnimated(true, completion: nil)
    
    // updateOrganizations
    StorageManager.sharedInstance.updateOrganization(selectedOrganization.id)
  }
  
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
  }
}
