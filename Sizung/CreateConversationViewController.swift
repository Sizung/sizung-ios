//
//  CreateConversationViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 17/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class CreateConversationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

  @IBOutlet weak var titleButton: UILabel!
  @IBOutlet weak var conversationNameTextField: UITextField!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var addMemberContainer: UIView!
  @IBOutlet weak var addMemberTextField: UITextField!

  @IBOutlet weak var inviteButton: UIButton!
  @IBOutlet weak var inviteButtonConstraint: NSLayoutConstraint!

  var conversation = Conversation(organizationId: Configuration.getSelectedOrganization()!)

  var storageManager: OrganizationStorageManager?

  var filterString: String?

  var delegate: ConversationCreateDelegate?

  var possibleMembers: [User] {
    get {
      let conversationMembers = conversation.members.map {user in
        return storageManager!.users[user.id]!
      }
      let diff = Set(storageManager!.users.collection).subtract(conversationMembers)
      if let filterString = filterString {
        return Array(diff).filter { user in
          return user.fullName.lowercaseString.containsString(filterString.lowercaseString)        }
      } else {
        return Array(diff)
      }
    }
  }

  var addMode = false

  var collection: [User] {
    get {
      guard storageManager != nil && conversation.members != nil else {
        return []
      }

      if addMode {
        return possibleMembers
      } else {
        return conversation.members.map {user in
          return (storageManager?.users[user.id])!
        }
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.addMemberContainer.layer.borderColor = UIColor.lightGrayColor().CGColor
    self.addMemberContainer.layer.borderWidth = 1

    self.tableView.registerNib(R.nib.memberTableViewCell)

    // add the current user
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.storageManager = storageManager
        let authToken = AuthToken(data: Configuration.getSessionToken())
        let user = storageManager.users[authToken.getUserId()]!

        if self.conversation.new {
          self.conversation.members.append(user)
        }
    }

    conversationNameTextField.becomeFirstResponder()
    conversationNameTextField.text = conversation.title

    if !conversation.new {
      titleButton.text = "Edit '\(conversation.title)'"
    }

    addMode = self.conversation.new

    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillBeHidden(_:)), name: UIKeyboardWillHideNotification, object: nil)
  }

  func keyboardDidShow(notification: NSNotification) {
    if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
      let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
      self.tableView.contentInset = contentInsets
      self.tableView.scrollIndicatorInsets = contentInsets
    }
  }

  func keyboardWillBeHidden(notification: NSNotification) {
    let contentInsets = UIEdgeInsetsZero
    self.tableView.contentInset = contentInsets
    self.tableView.scrollIndicatorInsets = contentInsets
  }

  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return collection.count
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.memberTableViewCell.identifier, forIndexPath: indexPath) as? MemberTableViewCell {

      let user = collection[indexPath.row]

      cell.avatarImage.user = user
      cell.nameLabel.text = user.fullName

      if self.conversation.members.contains(user) {
        cell.deleteButton.hidden = false
        cell.deleteButton.addTarget(self, action: #selector(self.removeMember), forControlEvents: .TouchUpInside)
        cell.selectionStyle = .None
      } else {
        cell.deleteButton.hidden = true
        cell.selectionStyle = .Default
      }

      return cell
    } else {
      fatalError()
    }
  }

  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let user = collection[indexPath.row]
    if !self.conversation.members.contains(user) {
      self.conversation.members.append(user)
      self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
    }
  }

  @IBAction func close(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }

  @IBAction func save(sender: UIButton) {

    conversation.title = conversationNameTextField.text

    guard conversation.title.characters.count > 0 else {
      InAppMessage.showErrorMessage("Please enter a title")
      conversationNameTextField.becomeFirstResponder()
      return
    }

    sender.enabled = false

    func successFunc(conversation: Conversation) {
      self.dismissViewControllerAnimated(true, completion: nil)
      delegate?.conversationCreated(conversation)
    }

    func errorFunc(error: StorageError) {
      InAppMessage.showErrorMessage("There has been an error saving your conversation - Please try again")
      sender.enabled = true
    }

    // save conversation
    if conversation.new {
      storageManager?.createConversation(conversation).onSuccess(callback: successFunc).onFailure(callback: errorFunc)
    } else {
      storageManager?.updateConversation(conversation).onSuccess(callback: successFunc).onFailure(callback: errorFunc)
    }
  }

  func removeMember(sender: UIButton) {

    let buttonPosition = sender.convertPoint(CGPoint.zero, toView: self.tableView)
    if let indexPath = self.tableView.indexPathForRowAtPoint(buttonPosition) {
      self.conversation.members.removeAtIndex(indexPath.row)
      self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
    } else {
      fatalError()
    }
  }

  func textFieldDidBeginEditing(textField: UITextField) {
    addMode = true
    self.tableView.reloadData()
  }

  func textFieldDidEndEditing(textField: UITextField) {
    addMode = false
    self.tableView.reloadData()
  }

  func textFieldShouldReturn(textField: UITextField) -> Bool {
    filterString = nil
    textField.text = ""
    return false
  }

  @IBAction func inviteMember(sender: AnyObject) {
    guard let newMemberEmail = filterString else {
      return
    }

    guard newMemberEmail.characters.count > 2 && newMemberEmail.containsString("@") else {
      InAppMessage.showErrorMessage("Please enter a valid email address")
      return
    }

    storageManager?.inviteOrganizationMember(newMemberEmail)
      .onSuccess { orgMember in
        self.addMemberTextField.resignFirstResponder()
        self.addMemberTextField.text = ""
        self.addMemberFieldChanged(self.addMemberTextField)

        let newUser = User(userId: orgMember.memberId, email: newMemberEmail)

        self.storageManager!.users.append(newUser)
        self.storageManager!.members.append(orgMember)

        self.conversation.members.append(newUser)

        self.tableView.reloadData()
      }.onFailure { _ in
        InAppMessage.showErrorMessage("Something went wrong - Please try again")
    }
  }

  @IBAction func addMemberFieldChanged(textField: UITextField) {

    if textField.text!.characters.count > 2 && textField.text!.containsString("@") {
      inviteButtonConstraint.priority = UILayoutPriorityDefaultHigh - 1
      self.inviteButton.hidden = false
      UIView.animateWithDuration(0.3) {
        self.view.layoutIfNeeded()
        self.inviteButton.alpha = 1
      }
    } else {
      inviteButtonConstraint.priority = UILayoutPriorityDefaultHigh + 1
      UIView.animateWithDuration(0.3, animations: {
        self.view.layoutIfNeeded()
        self.inviteButton.alpha = 0
        }, completion: { _ in
          self.inviteButton.hidden = true
      })
    }

    filterString = textField.text
    if filterString?.characters.count == 0 {
      filterString = nil
    }
    self.tableView.reloadData()
  }
}

protocol ConversationCreateDelegate {
  func conversationCreated(conversation: Conversation)
}
