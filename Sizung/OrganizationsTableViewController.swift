//
//  OrganizationsTableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 21/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class OrganizationsTableViewController: UITableViewController {
  
  // MARK: Properties
  
  var organizations = [Organization]()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //  initial fetch
    self.updateData(self)
    self.refreshControl?.addTarget(self, action: #selector(OrganizationsTableViewController.updateData(_:)), forControlEvents: UIControlEvents.ValueChanged)
  }
  
  func updateData(sender:AnyObject){
    
    let apiClient = APIClient()
    apiClient.getOrganizations()
      .onSuccess() { organizations in
        self.organizations = organizations
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
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // MARK: - Table view data source
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return organizations.count
  }
  
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cellIdentifier = "SizungTableViewCell"
    let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SizungTableViewCell
    
    let organization = organizations[indexPath.row]
    
    cell.textLabel!.text = organization.name
    
    return cell
  }
  
  
  /*
   // Override to support conditional editing of the table view.
   override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
   // Return false if you do not want the specified item to be editable.
   return true
   }
   */
  
  /*
   // Override to support editing the table view.
   override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
   if editingStyle == .Delete {
   // Delete the row from the data source
   tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
   } else if editingStyle == .Insert {
   // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
   }
   }
   */
  
  /*
   // Override to support rearranging the table view.
   override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
   
   }
   */
  
  /*
   // Override to support conditional rearranging of the table view.
   override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
   // Return false if you do not want the item to be re-orderable.
   return true
   }
   */
  
  
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showOrganization" {
      let conversationsViewController = segue.destinationViewController as! ConversationsTableViewController
      
      // Get the cell that generated this segue.
      if let selectedCell = sender as? SizungTableViewCell {
        let indexPath = tableView.indexPathForCell(selectedCell)!
        let selectedOrganization = organizations[indexPath.row]
        conversationsViewController.organization = selectedOrganization
        conversationsViewController.navigationItem.title = selectedOrganization.name
      }
    }
  }
  
  
}
