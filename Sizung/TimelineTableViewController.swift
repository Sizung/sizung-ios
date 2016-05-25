//
//  TimelineTableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 23/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import Spine

class TimelineTableViewController: BasicTableViewController {
  
  var conversation: Conversation?
  
  override func updateData(sender:AnyObject){
    
    if let conversationId = conversation?.id {
      let apiClient = APIClient()
      apiClient.getConversationObjects(conversationId)
        .onSuccess() { conversationObjects in
          self.modelList = conversationObjects as [TableViewCellDisplayable]
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
  }
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
   // Get the new view controller using segue.destinationViewController.
   // Pass the selected object to the new view controller.
   }
   */
  
}
