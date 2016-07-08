//
//  DeliverableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 14/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import AlamofireImage

class DeliverableViewController: UIViewController,
  UIPopoverPresentationControllerDelegate,
CalendarViewDelegate {

  @IBOutlet weak var statusButton: UIButton!
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var assigneeImageView: AvatarImageView!

  var deliverable: Deliverable!

  override func viewDidLoad() {
    super.viewDidLoad()

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        storageManager.getUser(self.deliverable.assigneeId)
          .onSuccess { user in
            self.assigneeImageView.user = user
        }
    }

    backButton.setTitle("< \(deliverable.title)", forState: .Normal)

    updateStatusText()
  }

  func updateStatusText() {
    var statusString = deliverable.status

    if !deliverable.isCompleted(), let dueDate = deliverable.dueOn {
      statusString = DueDateHelper.getDueDateString(dueDate)
    }

    statusButton.setTitle(statusString, forState: .Normal)
  }

  @IBAction func close(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }


  // MARK: - Navigation

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

    if let timelineTableViewController = segue.destinationViewController
      as? TimelineTableViewController {
      timelineTableViewController.timelineParent = deliverable
    }
  }

  @IBAction func showStatusPopover(sender: UIButton) {

    if !deliverable.isCompleted() {

      let optionMenu = UIAlertController(title: nil, message: "Edit", preferredStyle: .ActionSheet)

      let dateAction = UIAlertAction(title: "Change due date", style: .Default, handler: { _ in
        self.showDatePicker(sender)
      })

      let completeAction = UIAlertAction(title: "Mark as complete", style: .Default, handler: { _ in
        self.deliverable.setCompleted()
        self.updateDeliverable()
      })

      let archiveAction = UIAlertAction(title: "Archive", style: .Default, handler: { _ in
        self.deliverable.archived = true
        self.updateDeliverable()
      })

      let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)

      optionMenu.addAction(dateAction)
      optionMenu.addAction(completeAction)
      optionMenu.addAction(archiveAction)
      optionMenu.addAction(cancelAction)

      self.presentViewController(optionMenu, animated: true, completion: nil)
    }
  }

  func popoverPresentationControllerDidDismissPopover(
    popoverPresentationController: UIPopoverPresentationController
    ) {
      print("dismiss popover")
  }

  // show previous view controller
  @IBAction func back(sender: AnyObject) {
    self.navigationController?.popViewControllerAnimated(true)
  }

  func showDatePicker(sender: UIButton) {

    let calendarController = R.nib.calendarViewController.firstView(owner: nil)!
    calendarController.calendarViewDelegate = self
    calendarController.currentDate = deliverable.dueOn

    calendarController.modalPresentationStyle = .Popover
    self.presentViewController(calendarController, animated: true, completion: nil)

    let popoverController = calendarController.popoverPresentationController!
    popoverController.permittedArrowDirections = .Any
    popoverController.sourceView = sender
    popoverController.delegate = self
  }

  func didSelectDate(date: NSDate) {
    self.deliverable.dueOn = date
    self.updateDeliverable()
  }

  func updateDeliverable() {
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        storageManager.updateDeliverable(self.deliverable)
          .onSuccess { deliverable in
            storageManager.deliverables.insertOrUpdate([deliverable])
            self.updateStatusText()
        }
    }
  }
}
