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

    segmentedControl.items = ["PRIORITIES", "CHAT", "ACTIONS"]
    segmentedControl.thumbColors = [Color.TODISCUSS, Color.CHAT, Color.TODO]
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
        agendaItemsTableViewController.conversation = self.conversation

        self.mainPageViewController.orderedViewControllers.append(agendaItemsTableViewController)

        let timelineTableViewController = R.storyboard.conversation.timelineTableViewController()!
        timelineTableViewController.timelineParent = self.conversation
        self.mainPageViewController.orderedViewControllers.append(timelineTableViewController)

        let deliverablesTableViewController =
          R.storyboard.conversation.conversationDeliverablesTableViewController()!
        deliverablesTableViewController.conversation = self.conversation
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

    agendaItem = addItemToFab("AGENDA", color: Color.TODISCUSS, icon: R.image.priority()!, handler: createAgenda)

    attachmentItem = addItemToFab("ATTACHMENT", color: Color.ATTACHMENT, icon: R.image.attachment()!, handler: createAttachment)

    actionItem = addItemToFab("ACTION", color: Color.TODO, icon: R.image.action()!, handler: createAction)

    self.view.addSubview(floatingActionButton!)
  }

  func addItemToFab(title: String, color: UIColor, icon: UIImage, handler: (KCFloatingActionButtonItem)->()) -> KCFloatingActionButtonItem {
    let item = KCFloatingActionButtonItem()
    item.title = title
    item.buttonColor = color
    item.icon = icon
    item.handler = handler

    item.iconImageView.tintColor = UIColor.whiteColor()
    item.iconImageView.contentMode = .ScaleAspectFit

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
    print(imageName)
  }

  func didPickFile(file: NSData!, fileName: String!) {
    print(fileName)
  }
}
