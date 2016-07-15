//
//  AgendaItemViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 15/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class AgendaItemViewController: UIViewController {

  @IBOutlet weak var statusButton: UIButton!

  var agendaItem: AgendaItem!

  @IBOutlet weak var titleBar: UIView!
  @IBOutlet weak var titleLabel: UILabel!

  @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var titleBottomConstraint: NSLayoutConstraint!
  var oldConstraintConstant: CGFloat = 0

  override func viewDidLoad() {
    super.viewDidLoad()

    self.titleLabel.text = self.agendaItem.title
    statusButton.setTitle(agendaItem.status, forState: .Normal)

    oldConstraintConstant = titleTopConstraint.constant
    registerForKeyboardChanges()
  }

  @IBAction func close(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }

  // MARK: - Navigation

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

    if let timelineTableViewController = segue.destinationViewController
      as? TimelineTableViewController {
        timelineTableViewController.timelineParent = agendaItem
    }
  }

  @IBAction func showStatusPopover(sender: UIButton) {

    if !agendaItem.isCompleted() {

      let optionMenu = UIAlertController(title: nil, message: "Edit", preferredStyle: .ActionSheet)

      let completeAction = UIAlertAction(title: "Mark as complete", style: .Default, handler: { _ in
        self.agendaItem.setCompleted()
        self.updateAgendaItem()
      })

      let archiveAction = UIAlertAction(title: "Archive", style: .Default, handler: { _ in
        self.agendaItem.archived = true
        self.updateAgendaItem()
      })

      let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)

      optionMenu.addAction(completeAction)
      optionMenu.addAction(archiveAction)
      optionMenu.addAction(cancelAction)

      self.presentViewController(optionMenu, animated: true, completion: nil)
    }
  }

  func updateAgendaItem() {
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        storageManager.updateAgendaItem(self.agendaItem)
          .onSuccess { agendaItem in
            storageManager.agendaItems.insertOrUpdate([agendaItem])

            // update status text
            self.statusButton.setTitle(agendaItem.status, forState: .Normal)
        }
    }
  }

  @IBAction func back(sender: AnyObject) {
    self.navigationController?.popViewControllerAnimated(true)
  }

  func registerForKeyboardChanges() {
    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: #selector(self.keyboardWillShow),
      name: UIKeyboardWillShowNotification,
      object: nil
    )

    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: #selector(self.keyboardWillHide),
      name: UIKeyboardWillHideNotification,
      object: nil
    )
  }

  func keyboardWillShow() {
    self.titleTopConstraint.constant = 0
    self.titleBottomConstraint.constant = 0
    UIView.animateWithDuration(5) {
      self.titleLabel.text = nil
      self.titleBar.layoutIfNeeded()
    }
  }

  func keyboardWillHide() {
    self.titleTopConstraint.constant = oldConstraintConstant
    self.titleBottomConstraint.constant = oldConstraintConstant
    UIView.animateWithDuration(5) {
      self.titleLabel.text = self.agendaItem.title
      self.titleBar.layoutIfNeeded()
    }
  }
}
