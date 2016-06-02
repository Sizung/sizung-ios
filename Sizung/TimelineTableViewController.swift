//
//  TimelineTableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 23/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class TimelineTableViewController: BasicTableViewController {
  
  var conversation: Conversation?
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    self.navigationController?.setToolbarHidden(false, animated: true)
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    
    self.navigationController?.setToolbarHidden(true, animated: true)
  }
  

  
  override func updateData(sender:AnyObject){
    
//    if let conversationId = conversation?.id {
//      let apiClient = APIClient()
//      apiClient.getConversationObjects(conversationId)
//        .onSuccess() { conversationObjects in
//          self.modelList = conversationObjects as [TableViewCellDisplayable]
//        }.onFailure() { error in
//          print(error)
//          switch error {
//          case .Unauthorized:
//            print("unauthorized")
////            self.navigationController?.performSegueWithIdentifier("showLogin", sender: self)
//          default:
//            let alertController = UIAlertController(title: "Unkown error occured!", message:
//              "Please try again!", preferredStyle: UIAlertControllerStyle.Alert)
//            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
//            
//            self.presentViewController(alertController, animated: true, completion: nil)
//          }
//        }.onComplete() { _ in
//          self.refreshControl?.endRefreshing()
//          self.tableView.reloadData()
//      }
//    }
  }
  
  
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    switch segue.identifier {
    case "showAgendas"?:
      let destinationViewController = segue.destinationViewController as! AgendaItemsTableViewController
      destinationViewController.conversation = conversation
      
    case "showDeliverables"?:
      let destinationViewController = segue.destinationViewController as! DeliverablesTableViewController
    default:
      fatalError("unknown segue identifier \(segue.identifier) in TimelineTableViewController")
      
    }
  }
  
  
}
