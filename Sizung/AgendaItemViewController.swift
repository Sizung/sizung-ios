//
//  AgendaItemViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 15/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import KCFloatingActionButton
import ImageFilesPicker
import MRProgress

class AgendaItemViewController: UIViewController,
ActionCreateDelegate,
FilesPickerDelegate,
AgendaItemCreateDelegate {

  @IBOutlet weak var agendaOwnerAvatarView: AvatarImageView!
  @IBOutlet weak var titleButton: UIButton!
  @IBOutlet weak var statusButton: UIButton!

  var agendaItem: AgendaItem!

  var floatingActionButton: KCFloatingActionButton?

  var filePicker = JVTImageFilePicker()

  var storageManager: OrganizationStorageManager?

  override func viewDidLoad() {
    super.viewDidLoad()

    self.titleButton.setTitle(self.agendaItem.title, forState: .Normal)

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.storageManager = storageManager

        self.agendaOwnerAvatarView.user = storageManager.users[self.agendaItem.ownerId]
    }

    initFloatingActionButton()
  }

  // MARK: - Navigation

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

    if let timelineTableViewController = segue.destinationViewController
      as? TimelineTableViewController {
        timelineTableViewController.timelineParent = agendaItem
    }
  }

  @IBAction func edit(sender: AnyObject) {
    let createAgendaItemViewController = R.storyboard.agendaItem.create()!
    createAgendaItemViewController.agendaItem = self.agendaItem
    createAgendaItemViewController.conversation = self.storageManager?.conversations[agendaItem.conversationId]
    createAgendaItemViewController.agendaItemCreateDelegate = self
    self.presentViewController(createAgendaItemViewController, animated: true, completion: nil)
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

            if agendaItem.archived == true {
              self.navigationController?.popViewControllerAnimated(true)
            }

            // update status text
            self.statusButton.setTitle(agendaItem.status, forState: .Normal)
        }
    }
  }

  @IBAction func back(sender: AnyObject) {

    let transition = CATransition()
    transition.duration = 0.3
    transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    transition.type = kCATransitionPush
    transition.subtype = kCATransitionFromBottom

    self.navigationController?.view.layer.addAnimation(transition, forKey: nil)

    self.navigationController?.popViewControllerAnimated(false)

  }

  // MARK: - FAB

  func initFloatingActionButton() {

    floatingActionButton = KCFloatingActionButton()
    floatingActionButton?.plusColor = UIColor.whiteColor()
    floatingActionButton?.buttonColor = Color.ADDBUTTON

    addItemToFab("ATTACHMENT", color: Color.ATTACHMENT, icon: R.image.attachment()!, handler: createAttachment)

    addItemToFab("ACTION", color: Color.TODO, icon: R.image.action()!, handler: createAction)

    self.view.addSubview(floatingActionButton!)

    self.filePicker.delegate = self
  }

  func addItemToFab(title: String, color: UIColor, icon: UIImage, handler: (KCFloatingActionButtonItem)->()) -> KCFloatingActionButtonItem {
    let item = KCFloatingActionButtonItem()
    item.title = title
    item.buttonColor = color
    item.icon = icon
    item.handler = handler

    item.iconImageView.tintColor = UIColor.whiteColor()
    item.iconImageView.contentMode = .Center

    floatingActionButton?.addItem(item: item)

    return item
  }

  func createAttachment(buttonItem: KCFloatingActionButtonItem) {
    self.filePicker.presentFilesPickerOnController(self.parentViewController)
  }

  func createAction(buttonItem: KCFloatingActionButtonItem) {
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

  func didPickImage(image: UIImage!, withImageName imageName: String!) {
    self.didPickFile(UIImageJPEGRepresentation(image, 0.9), fileName: "photo.jpg")
  }

  func didPickFile(file: NSData!, fileName: String!) {

    let progressView = MRProgressOverlayView.showOverlayAddedTo(self.view, animated: true)
    progressView.mode = .DeterminateCircular

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in

        let parentItem = self.agendaItem

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

  func agendaItemCreated(agendaItem: AgendaItem) {
    self.titleButton.setTitle(agendaItem.title, forState: .Normal)
    InAppMessage.showSuccessMessage("Updated agenda")
  }
}
