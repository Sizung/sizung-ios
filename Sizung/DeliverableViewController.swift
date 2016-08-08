//
//  DeliverableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 14/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import KCFloatingActionButton
import ImageFilesPicker
import MRProgress

class DeliverableViewController: UIViewController,
  UIPopoverPresentationControllerDelegate,
  CalendarViewDelegate,
  KCFloatingActionButtonDelegate,
  FilesPickerDelegate,
ActionCreateDelegate {

  @IBOutlet weak var titleButton: UIButton!
  @IBOutlet weak var statusButton: UIButton!
  @IBOutlet weak var assigneeImageView: AvatarImageView!

  @IBOutlet weak var parentAgendaItemButton: UIButton!
  @IBOutlet weak var parentAgendaItemDistance: NSLayoutConstraint!

  var deliverable: Deliverable!

  var parentAgendaItem: AgendaItem?

  var floatingActionButton: KCFloatingActionButton?

  var filePicker = JVTImageFilePicker()

  override func viewDidLoad() {
    super.viewDidLoad()

    //    StorageManager.storageForSelectedOrganization()
    //      .onSuccess { storageManager in
    //        storageManager.getUser(self.deliverable.assigneeId)
    //          .onSuccess { user in
    //            self.assigneeImageView.user = user
    ////
    ////            if let agendaItem = storageManager.agendaItems[self.deliverable.parentId] {
    ////              self.backButton.setTitle("< \(agendaItem.title)", forState: .Normal)
    ////            }
    //        }
    //    }

    update()

    initFloatingActionButton()
  }

  @IBAction func edit(sender: AnyObject) {
    let createDeliverableViewController = R.storyboard.deliverable.create()!
    createDeliverableViewController.action = self.deliverable
    createDeliverableViewController.actionCreateDelegate = self
    self.presentViewController(createDeliverableViewController, animated: true, completion: nil)
  }

  func update() {

    self.titleButton.setTitle(self.deliverable.title, forState: .Normal)

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.assigneeImageView.user = storageManager.users[self.deliverable.assigneeId]


        if let parentAgendaItem = storageManager.agendaItems[self.deliverable.parentId] {
          self.parentAgendaItem = parentAgendaItem
          self.parentAgendaItemButton.hidden = false
          self.parentAgendaItemDistance.priority = UILayoutPriorityDefaultHigh + 1

          UIView.animateWithDuration(0.3) {
            self.parentAgendaItemButton.alpha = 1
            self.view.layoutIfNeeded()
          }

        } else {
          self.parentAgendaItem = nil
          self.parentAgendaItemDistance.priority = UILayoutPriorityDefaultHigh - 1

          UIView.animateWithDuration(0.3, animations: {
            self.parentAgendaItemButton.alpha = 0
            self.view.layoutIfNeeded()
            }, completion: { _ in
              self.parentAgendaItemButton.hidden = true
          })
        }
    }

    var statusBorderColor = Color.AGENDAITEM
    var statusBackgroundColor = UIColor.whiteColor()
    var statusTextColor = Color.AGENDAITEM
    var statusString = "…"

    if deliverable.isCompleted() {
      statusBorderColor = Color.AGENDAITEM
      statusBackgroundColor = statusBorderColor
    } else if deliverable.isOverdue() {
      statusBackgroundColor = statusBorderColor
      statusString = "!"
      statusTextColor = UIColor.whiteColor()
    }

    statusButton.setTitle(statusString, forState: .Normal)
    statusButton.setTitleColor(statusTextColor, forState: .Normal)
    statusButton.layer.borderUIColor = statusBorderColor
    statusButton.backgroundColor = statusBackgroundColor

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

      var statusString = deliverable.getStatus()

      if deliverable.archived == true {
        statusString = "Archived"
      } else if !deliverable.isCompleted(), let dueDate = deliverable.dueOn {
        statusString = DueDateHelper.getDueDateString(dueDate)
      }


      let optionMenu = UIAlertController(title: nil, message: statusString, preferredStyle: .ActionSheet)

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

    if parentAgendaItem == nil {
      let transition = CATransition()
      transition.duration = 0.3
      transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
      transition.type = kCATransitionPush
      transition.subtype = kCATransitionFromBottom

      self.navigationController?.view.layer.addAnimation(transition, forKey: nil)

      self.navigationController?.popViewControllerAnimated(false)
    } else {
      self.navigationController?.popViewControllerAnimated(true)
    }

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
            if deliverable.archived == true {
              self.navigationController?.popViewControllerAnimated(true)
            }
            self.update()
        }
    }
  }

  // MARK: - FAB

  func initFloatingActionButton() {

    floatingActionButton = KCFloatingActionButton()
    floatingActionButton?.plusColor = UIColor.whiteColor()
    floatingActionButton?.buttonColor = Color.ADDBUTTON
    floatingActionButton?.fabDelegate = self
    self.view.addSubview(floatingActionButton!)

    self.filePicker.delegate = self
  }

  func emptyKCFABSelected(fab: KCFloatingActionButton) {
    self.filePicker.presentFilesPickerOnController(self.parentViewController)
  }

  func createAttachment(buttonItem: KCFloatingActionButtonItem) {
    self.filePicker.presentFilesPickerOnController(self.parentViewController)
  }

  func didPickImage(image: UIImage!, withImageName imageName: String!) {
    self.didPickFile(UIImageJPEGRepresentation(image, 0.9), fileName: "photo.jpg")
  }

  func didPickFile(file: NSData!, fileName: String!) {

    let progressView = MRProgressOverlayView.showOverlayAddedTo(self.view, animated: true)
    progressView.mode = .DeterminateCircular

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in

        let parentItem = self.deliverable

        let fileType = Helper.getMimeType(fileName)

        let attachment = Attachment(
          fileName: fileName,
          fileSize: file.length,
          fileType: fileType,
          parentId: parentItem.id,
          parentType: parentItem.type
        )
        storageManager.uploadAttachment(attachment, data: file, progress: { progress in
          progressView.setProgress(progress, animated: true)
        })
          .onSuccess { attachment in
            InAppMessage.showSuccessMessage("File successfully uploaded")
          }.onFailure { error in
            InAppMessage.showErrorMessage("There has been an error uploading your file - Please try again")
          }.onComplete { _ in
            progressView.dismiss(true)
        }
    }
  }

  func actionCreated(action: Deliverable) {
    self.deliverable = action

    self.update()
    InAppMessage.showSuccessMessage("Updated action")
  }
}
