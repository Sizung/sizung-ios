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
      let cell = tableView.dequeueReusableCellWithIdentifier("SizungTableViewCell", forIndexPath: indexPath)
      let organization = organizations[indexPath.row]
      cell.textLabel!.text = organization.attributes.name
      return cell
    }
  }
  
  override func viewDidAppear(animated: Bool) {
    let storageManager = StorageManager.sharedInstance
    if !storageManager.isInitialized {
      storageManager.updateOrganizations()
    }
  }
  
  func updateData(){
    StorageManager.sharedInstance.updateOrganizations()
  }
  
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showOrganization" {
      
      // Get the cell that generated this segue.
      if let selectedCell = sender as? SizungTableViewCell {
        let indexPath = tableView.indexPathForCell(selectedCell)!
        let selectedOrganization = StorageManager.sharedInstance.organizations[indexPath.row]
        
        KeychainWrapper.setString(selectedOrganization.id!, forKey: Configuration.Settings.SELECTED_ORGANIZATION)
        self.dismissViewControllerAnimated(true, completion: nil)
      }
    }
  }
}
