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
  FilesPickerDelegate {

  @IBOutlet weak var titleBar: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var statusBar: UIView!
  @IBOutlet weak var statusButton: UIButton!
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var assigneeImageView: AvatarImageView!

  @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var titleBottomConstraint: NSLayoutConstraint!
  var oldConstraintConstant: CGFloat = 0

  var deliverable: Deliverable!

  var floatingActionButton: KCFloatingActionButton?

  var filePicker = JVTImageFilePicker()

  override func viewDidLoad() {
    super.viewDidLoad()

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        storageManager.getUser(self.deliverable.assigneeId)
          .onSuccess { user in
            self.assigneeImageView.user = user

            if let agendaItem = storageManager.agendaItems[self.deliverable.parentId] {
              self.backButton.setTitle("< \(agendaItem.title)", forState: .Normal)
            }
        }
    }

    self.titleLabel.text = self.deliverable.title

    updateStatusText()

    oldConstraintConstant = titleTopConstraint.constant
    registerForKeyboardChanges()

    initFloatingActionButton()
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
      self.titleLabel.text = self.deliverable.title
      self.titleBar.layoutIfNeeded()
    }
  }

  func updateStatusText() {
    var statusString = deliverable.status

    if deliverable.archived == true {
      statusString = "Archived"
    } else if !deliverable.isCompleted(), let dueDate = deliverable.dueOn {
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
            if deliverable.archived == true {
              self.navigationController?.popViewControllerAnimated(true)
            }
            self.updateStatusText()
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

  func actionCreated(action: Deliverable) {

    let actionViewController = R.storyboard.deliverable.initialViewController()!
    actionViewController.deliverable = action

    self.navigationController?.pushViewController(actionViewController, animated: false)
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
}
