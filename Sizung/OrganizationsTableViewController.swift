//
//  OrganizationsTableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 21/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class OrganizationsTableViewController: BasicTableViewController {
  
  override func updateData(sender: AnyObject) {
    let apiClient = APIClient()
    apiClient.getOrganizations()
      .onSuccess() { organizations in
        self.modelList = organizations
        self.tableView.reloadData()
      }.onFailure() { error in
        print(error)
        switch error {
        case .Unauthorized:
          self.navigationController?.performSegueWithIdentifier("showLogin", sender: self)
        default:
          let alertController = UIAlertController(title: "Unkown error occured!", message:
            "Please try again!", preferredStyle: UIAlertControllerStyle.Alert)
          alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
          
          self.presentViewController(alertController, animated: true, completion: nil)
        }
      }.onComplete() { _ in
        self.refreshControl?.endRefreshing()
    }

  }
  
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showOrganization" {
      let conversationsViewController = segue.destinationViewController as! ConversationsTableViewController
      
      // Get the cell that generated this segue.
      if let selectedCell = sender as? SizungTableViewCell {
        let indexPath = tableView.indexPathForCell(selectedCell)!
        if let selectedOrganization = self.modelList[indexPath.row] as? Organization {
          conversationsViewController.organization = selectedOrganization
          conversationsViewController.navigationItem.title = selectedOrganization.name
        }
      }
    }
  }
  
  
}
