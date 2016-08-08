//
//  AgendaItemActionList.swift
//  Sizung
//
//  Created by Markus Klepp on 08/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import KCFloatingActionButton

class AgendaItemActionListController: UIViewController,
KCFloatingActionButtonDelegate,
ActionCreateDelegate {

  var agendaItem: AgendaItem?

  var floatingActionButton: KCFloatingActionButton?

  override func viewDidLoad() {
    floatingActionButton = KCFloatingActionButton()
    floatingActionButton?.plusColor = UIColor.whiteColor()
    floatingActionButton?.buttonColor = Color.ADDBUTTON
    floatingActionButton?.fabDelegate = self

    self.view.addSubview(floatingActionButton!)
  }

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

  func emptyKCFABSelected(fab: KCFloatingActionButton) {
    createAction()
  }

  func createAction() {
    let createDeliverableViewController = R.storyboard.deliverable.create()!
    createDeliverableViewController.parent = self.agendaItem
    createDeliverableViewController.actionCreateDelegate = self
    self.presentViewController(createDeliverableViewController, animated: true, completion: nil)
  }

  func actionCreated(action: Deliverable) {
    let actionViewController = R.storyboard.deliverable.initialViewController()!
    actionViewController.deliverable = action
    self.navigationController?.pushViewController(actionViewController, animated: false)
  }


}
