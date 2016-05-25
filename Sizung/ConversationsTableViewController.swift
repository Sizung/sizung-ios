//
//  ConversationsTableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 21/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class ConversationsTableViewController: BasicTableViewController {
  
  var organization : Organization?
  
  override func updateData(sender:AnyObject){
    
    if let organizationId = organization?.id {
      let apiClient = APIClient()
      apiClient.getConversations(organizationId)
        .onSuccess() { conversations in
          self.modelList = conversations
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
          self.tableView.reloadData()
      }
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
        if let selectedConversation = modelList[indexPath.row] as? Conversation {
          timelineTableViewController.conversation = selectedConversation
          timelineTableViewController.navigationItem.title = selectedConversation.title
        }
      }
    }
  }
  
  
}
