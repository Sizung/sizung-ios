//
//  AgendaItemsTableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 25/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class AgendaItemsTableViewController: BasicTableViewController {
  
  var conversation: Conversation?
  
  override func updateData(sender: AnyObject) {
    if let conversationId = conversation?.id {
      let apiClient = APIClient()
      apiClient.getAgendaItems(conversationId)
        .onSuccess() { agendaItems in
          self.modelList = agendaItems as [TableViewCellDisplayable]
        }.onFailure() { error in
          print(error)
          switch error {
          case .Unauthorized:
            print("unauthorized")
//            self.navigationController?.performSegueWithIdentifier("showLogin", sender: self)
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
}
