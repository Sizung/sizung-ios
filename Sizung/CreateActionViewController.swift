//
//  CreateActionViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 18/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class CreateActionViewController: UIViewController, UITextFieldDelegate, ActionContentDelegate {

  var action: Deliverable?

  var parent: BaseModel?
  var actionCreateDelegate: ActionCreateDelegate?
  var storageManager: OrganizationStorageManager?

  var createActionContentViewController: CreateActionContentViewController?

  @IBOutlet weak var titleLabel: UILabel!
  var dueDate: NSDate?
  var assignee: User?

  @IBOutlet weak var actionNameTextField: UITextField!

  override func viewDidLoad() {
    super.viewDidLoad()

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.storageManager = storageManager

        if self.action == nil {
          let authToken = AuthToken(data: Configuration.getSessionToken())
          self.assignee = storageManager.users[authToken.getUserId()!]!
        } else {
          self.assignee = storageManager.users[self.action?.assigneeId]
          self.dueDate = self.action?.dueOn
        }

        self.createActionContentViewController!.updateAssignee(self.assignee)
        self.createActionContentViewController!.updateDueDate(self.dueDate)

        let conversation = storageManager.conversations[self.getConversationId()]!
        self.createActionContentViewController!.conversation = conversation
    }

    actionNameTextField.becomeFirstResponder()
    actionNameTextField.delegate = self

    if let title = action?.title {
      self.titleLabel.text = "Edit '\(title)'"
    }

    actionNameTextField.text = action?.title
  }

  @IBAction func close(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }

  @IBAction func save(sender: UIButton?) {

    if action == nil {
      switch parent {
      case let agendaItem as AgendaItem:
        action = AgendaItemDeliverable(agendaItemId: agendaItem.id)
      case let conversation as Conversation:
        action = Deliverable(conversationId: conversation.id)
      default:
        fatalError()
      }
    }

    action!.title = actionNameTextField.text
    action!.assigneeId = assignee?.id
    action!.dueOn = dueDate

    guard action!.title.characters.count > 0 else {
      InAppMessage.showErrorMessage("Please enter a title")
      actionNameTextField.becomeFirstResponder()
      return
    }

    sender?.enabled = false

    func successFunc(createdAction: Deliverable) {
      self.dismissViewControllerAnimated(true) {
        self.actionCreateDelegate?.actionCreated(createdAction)
      }
    }

    func errorFunc(error: StorageError) {
      InAppMessage.showErrorMessage("There has been an error saving your Agenda - Please try again")
      sender?.enabled = true
    }

    // save action
    if action!.new {
      storageManager?.createDeliverable(action!).onSuccess(callback: successFunc).onFailure(callback: errorFunc)
    } else {
      storageManager?.updateDeliverable(action!).onSuccess(callback: successFunc).onFailure(callback: errorFunc)
    }
  }

  func textFieldShouldReturn(textField: UITextField) -> Bool {
    self.save(nil)
    return true
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let navController = segue.destinationViewController as? UINavigationController {
      if let createActionContentViewController = navController.viewControllers.first as? CreateActionContentViewController {
        self.createActionContentViewController = createActionContentViewController
        createActionContentViewController.delegate = self
        createActionContentViewController.assignee = assignee
        createActionContentViewController.dueDate = dueDate
      } else {
        fatalError()
      }
    } else {
      fatalError()
    }
  }

  func getConversationId() -> String {
    switch parent {
    case is AgendaItem:
      return storageManager!.agendaItems[parent!.id]!.conversationId
    case is Conversation:
      return parent!.id
    default:
      if let parentAgendaItem = storageManager!.agendaItems[self.action!.parentId] {
        return parentAgendaItem.conversationId
      } else {
        return self.action!.parentId
      }
    }
  }

  func dueDateChanged(dueDate: NSDate) {
    self.dueDate = dueDate
  }

  func assigneeChanged(assignee: User) {
    self.assignee = assignee
  }
}

class CreateActionContentViewController: UIViewController, CalendarViewDelegate, AssigneeSelectedDelegate, UIPopoverPresentationControllerDelegate {

  var assignee: User?
  var dueDate: NSDate?
  var conversation: Conversation?

  var delegate: ActionContentDelegate?

  @IBOutlet weak var dueDateButton: UIButton!
  @IBOutlet weak var assigneeImageView: AvatarImageView!
  @IBOutlet weak var assigneeButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()

    updateAssignee(assignee)
    updateDueDate(dueDate)
  }

  func updateAssignee(assignee: User?) {

    self.assignee = assignee

    guard assigneeImageView != nil else {
      return
    }

    guard assigneeButton != nil else {
      return
    }

    if let assignee = assignee {
      self.assigneeImageView.user = assignee
      self.assigneeImageView.hidden = false
      if let firstName = assignee.firstName, lastName = assignee.lastName {
        self.assigneeButton.setTitle("\(firstName) \(lastName)", forState: .Normal)
      } else {
        self.assigneeButton.setTitle("", forState: .Normal)
      }
      self.assigneeButton.setTitle(assignee.fullName, forState: .Normal)
    } else {
      self.assigneeImageView.hidden = true
      self.assigneeButton.setTitle("No one assigned yet", forState: .Normal)
    }
  }

  func updateDueDate(date: NSDate?) {

    self.dueDate = date

    guard dueDateButton != nil else {
      return
    }

    var title = "No due date"
    if let dueDate = dueDate {
      let formatter = NSDateFormatter()
      formatter.dateStyle = .MediumStyle
      formatter.timeStyle = .NoStyle
      title = formatter.stringFromDate(dueDate)
    }
    self.dueDateButton.setTitle(title, forState: .Normal)
  }

  @IBAction func showDatePicker(sender: UIButton) {

    let calendarController = R.nib.calendarViewController.firstView(owner: nil)!
    calendarController.calendarViewDelegate = self

    calendarController.modalPresentationStyle = .Popover
    self.presentViewController(calendarController, animated: true, completion: nil)

    let popoverController = calendarController.popoverPresentationController!
    popoverController.permittedArrowDirections = .Any
    popoverController.sourceView = sender
    popoverController.delegate = self
  }

  func didSelectDate(date: NSDate) {
    self.updateDueDate(date)
    delegate?.dueDateChanged(date)
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let typedInfo = R.segue.createActionContentViewController.pickAssignee(segue: segue) {
      let assigneeSelctionViewController = typedInfo.destinationViewController
      assigneeSelctionViewController.delegate = self
      assigneeSelctionViewController.conversation = self.conversation
    }
  }

  func assigneeSelected(assignee: User) {
    self.navigationController?.popViewControllerAnimated(true)
    updateAssignee(assignee)
    delegate?.assigneeChanged(assignee)
  }
}

protocol ActionContentDelegate {
  func dueDateChanged(dueDate: NSDate)
  func assigneeChanged(assignee: User)
}

protocol ActionCreateDelegate {
  func actionCreated(action: Deliverable)
}
