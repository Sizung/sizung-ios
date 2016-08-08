//
//  AgendaItemActionList.swift
//  Sizung
//
//  Created by Markus Klepp on 08/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class AgendaItemActionListController: UIViewController {

  var agendaItem: AgendaItem?

  @IBAction func back(sender: AnyObject) {
    self.navigationController?.popViewControllerAnimated(true)
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if R.segue.agendaItemActionListController.embedActionList(segue: segue) != nil {
      if let agendaItemActionTableViewController = segue.destinationViewController as? DeliverablesTableViewController {
        agendaItemActionTableViewController.parent = self.agendaItem
        agendaItemActionTableViewController.filter = .All
      } else {
        fatalError()
      }
    } else {
      fatalError("unkown segue \(segue.identifier)")
    }
  }
}
