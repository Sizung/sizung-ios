//
//  ConversationViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 02/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import KCFloatingActionButton
import ImageFilesPicker
import MRProgress

class ConversationContentViewController: UIViewController,
  MainPageViewControllerDelegate,
  AgendaItemCreateDelegate,
  ActionCreateDelegate,
  KCFloatingActionButtonDelegate,
FilesPickerDelegate {

  @IBOutlet weak var segmentedControl: SizungSegmentedControl!

  var mainPageViewController: MainPageViewController!

  var conversation: Conversation!

  var floatingActionButton: KCFloatingActionButton?
  var agendaItem: KCFloatingActionButtonItem?
  var attachmentItem: KCFloatingActionButtonItem?
  var actionItem: KCFloatingActionButtonItem?

  var filePicker = JVTImageFilePicker()

  override func viewDidLoad() {
    super.viewDidLoad()

    segmentedControl.items = ["AGENDA", "DISCUSSION", "ACTION"]
    segmentedControl.thumbColors = [Color.AGENDAITEM, Color.DISCUSSION, Color.ACTION]
    segmentedControl.addTarget(
      self,
      action: #selector(self.segmentedControlDidChange),
      forControlEvents: .ValueChanged
    )

    filePicker.delegate = self

    initFloatingActionButton()
  }

  func segmentedControlDidChange(sender: SizungSegmentedControl) {

    let selectedIndex = sender.selectedIndex

    self.mainPageViewController.setSelectedIndex(selectedIndex)

    configureFabForIndex(selectedIndex)
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if R.segue.conversationContentViewController.embed(segue: segue) != nil {
      if let mainPageViewController = segue.destinationViewController as? MainPageViewController {
        self.mainPageViewController = mainPageViewController
        self.mainPageViewController.mainPageViewControllerDelegate = self

        let agendaItemsTableViewController =
          R.storyboard.conversation.agendaItemsTableViewController()!
        agendaItemsTableViewController.filter = .All
        agendaItemsTableViewController.conversation = self.conversation

        self.mainPageViewController.orderedViewControllers.append(agendaItemsTableViewController)

        let timelineTableViewController = R.storyboard.conversation.timelineTableViewController()!
        timelineTableViewController.timelineParent = self.conversation
        self.mainPageViewController.orderedViewControllers.append(timelineTableViewController)

        let deliverablesTableViewController =
          R.storyboard.conversation.conversationDeliverablesTableViewController()!
        deliverablesTableViewController.filter = .All
        deliverablesTableViewController.parent = self.conversation
        self.mainPageViewController.orderedViewControllers.append(deliverablesTableViewController)
      } else {
        fatalError("unexpected destinationviewcontroller " +
          "\(segue.destinationViewController.dynamicType)")
      }
    } else {
      fatalError("unkown segue \(segue.identifier)")
    }
  }

  func mainpageViewController(
    mainPageViewController: MainPageViewController,
    didSwitchToIndex index: Int) {
    segmentedControl.selectedIndex = index

    configureFabForIndex(index)
  }

  func configureFabForIndex(index: Int) {
    // show fab content on timeline only
    switch index {
    case 1:
      floatingActionButton?.addItem(item: agendaItem!)
      floatingActionButton?.addItem(item: attachmentItem!)
      floatingActionButton?.addItem(item: actionItem!)
    default:
      floatingActionButton?.removeItem(item: agendaItem!)
      floatingActionButton?.removeItem(item: attachmentItem!)
      floatingActionButton?.removeItem(item: actionItem!)
    }
  }

  func emptyKCFABSelected(fab: KCFloatingActionButton) {
    switch segmentedControl.selectedIndex {
    case 0:
      createAgenda(agendaItem!)
    case 2:
      createAction(actionItem!)
    default:
      fatalError("FAB should not be empty")
    }
  }

  func initFloatingActionButton() {

    floatingActionButton = KCFloatingActionButton()
    floatingActionButton?.fabDelegate = self
    floatingActionButton?.plusColor = UIColor.whiteColor()
    floatingActionButton?.buttonColor = Color.ADDBUTTON

    agendaItem = addItemToFab("AGENDA", color: Color.AGENDAITEM, icon: R.image.priority()!, handler: createAgenda)

    attachmentItem = addItemToFab("ATTACHMENT", color: Color.ATTACHMENT, icon: R.image.attachment()!, handler: createAttachment)

    actionItem = addItemToFab("ACTION", color: Color.ACTION, icon: R.image.checkmark()!, handler: createAction)

    self.view.addSubview(floatingActionButton!)
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

  func createAgenda(buttonItem: KCFloatingActionButtonItem) {
    let createAgendaItemViewController = R.storyboard.agendaItem.create()!
    createAgendaItemViewController.conversation = self.conversation
    createAgendaItemViewController.agendaItemCreateDelegate = self
    self.presentViewController(createAgendaItemViewController, animated: true, completion: nil)
  }

  func createAction(buttonItem: KCFloatingActionButtonItem) {
    let createDeliverableViewController = R.storyboard.deliverable.create()!
    createDeliverableViewController.parent = self.conversation
    createDeliverableViewController.actionCreateDelegate = self
    self.presentViewController(createDeliverableViewController, animated: true, completion: nil)
  }


  func agendaItemCreated(agendaItem: AgendaItem) {
    let agendaItemViewController = R.storyboard.agendaItem.initialViewController()!
    agendaItemViewController.agendaItem = agendaItem

    self.navigationController?.pushViewController(agendaItemViewController, animated: false)
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

        let parentItem = self.getCurrentItem()

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

  func getCurrentItem() -> BaseModel {
    switch self.navigationController?.topViewController {
    case let agendaItemViewController as AgendaItemViewController:
      return agendaItemViewController.agendaItem
    case let actionItemViewController as DeliverableViewController:
      return actionItemViewController.deliverable
    case let conversationContentViewController as ConversationContentViewController:
      return conversationContentViewController.conversation
    case let timelineTableViewController as TimelineTableViewController:
      return timelineTableViewController.timelineParent
    default:
      fatalError()
    }
  }
}
