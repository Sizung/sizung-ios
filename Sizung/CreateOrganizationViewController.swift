//
//  CreateOrganizationViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 09/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import MRProgress

class CreateOrganizationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

  @IBOutlet weak var titleButton: UILabel!
  @IBOutlet weak var organizationNameTextField: UITextField!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var addMemberContainer: UIView!
  @IBOutlet weak var addMemberTextField: UITextField!

  @IBOutlet weak var inviteButton: UIButton!
  @IBOutlet weak var inviteButtonConstraint: NSLayoutConstraint!

  var organization: Organization?

  var storageManager: OrganizationStorageManager?

  var filterString: String?

  var delegate: OrganizationCreateDelegate?

  var collection: [User] {
    get {
      if let storageManager = storageManager {
        return storageManager.users.collection
      } else {
        return []
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let authToken = AuthToken(data: Configuration.getSessionToken())

    if self.organization == nil {
      self.organization = Organization(ownerId: authToken.getUserId()!)
    }

    if organization!.new {
      self.addMemberContainer.hidden = true
    }

    self.addMemberContainer.layer.borderColor = UIColor.lightGrayColor().CGColor
    self.addMemberContainer.layer.borderWidth = 1

    self.tableView.registerNib(R.nib.memberTableViewCell)

    if !organization!.new {
      // if organization is not new load storage for it
      StorageManager.sharedInstance.storageForOrganizationId(self.organization!.id)
        .onSuccess { storageManager in
          self.storageManager = storageManager
          self.tableView.reloadData()
      }
    }

    organizationNameTextField.becomeFirstResponder()
    organizationNameTextField.text = organization!.name

    if !organization!.new {
      titleButton.text = "Edit Organization"
    }

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

      cell.deleteButton.hidden = false
      cell.deleteButton.addTarget(self, action: #selector(self.removeMember), forControlEvents: .TouchUpInside)

      return cell
    } else {
      fatalError()
    }
  }

  @IBAction func close(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }

  @IBAction func save(sender: UIButton) {

    organization!.name = organizationNameTextField.text

    guard organization!.name.characters.count > 0 else {
      InAppMessage.showErrorMessage("Please enter a title")
      organizationNameTextField.becomeFirstResponder()
      return
    }

    sender.enabled = false

    func successFunc(organization: Organization) {
      if self.organization!.new {

        self.organization = organization

        StorageManager.sharedInstance.storageForOrganizationId(organization.id)
          .onSuccess { storageManager in
            self.storageManager = storageManager

            self.tableView.reloadData()

            self.addMemberTextField.becomeFirstResponder()

            InAppMessage.showSuccessMessage("Organization successfully created\nNow invite someone")
            self.addMemberContainer.hidden = false
            UIView.animateWithDuration(0.3) {
              self.addMemberContainer.alpha = 1
            }
          }.onFailure { _ in
            InAppMessage.showErrorMessage("There has been an error saving your organization - Please try again")
        }
      } else {
        self.dismissViewControllerAnimated(true, completion: nil)
        delegate?.organizationCreated(self.organization!)
      }
      MRProgressOverlayView.dismissOverlayForView(self.view, animated: true)
    }

    func errorFunc(error: StorageError) {
      InAppMessage.showErrorMessage("There has been an error saving your organization - Please try again")
      sender.enabled = true
      MRProgressOverlayView.dismissOverlayForView(self.view, animated: true)
    }
    
    MRProgressOverlayView.showOverlayAddedTo(self.view, title: "Saving", mode: .Indeterminate, animated: true)

    // save conversation
    if organization!.new {
      StorageManager.sharedInstance.createOrganization(organization!.name).onSuccess(callback: successFunc).onFailure(callback: errorFunc)
    } else {
      StorageManager.sharedInstance.updateOrganization(organization!).onSuccess(callback: successFunc).onFailure(callback: errorFunc)
    }
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

        self.storageManager!.users.append(User(userId: orgMember.memberId, email: newMemberEmail))
        self.storageManager!.members.append(orgMember)
        self.tableView.reloadData()
      }.onFailure { _ in
        InAppMessage.showErrorMessage("Something went wrong - Please try again")
    }
  }

  func removeMember(sender: UIButton) {

    let alertController = UIAlertController(title: "Remove Member?", message:nil, preferredStyle: UIAlertControllerStyle.Alert)
    alertController.addAction(UIAlertAction(title: "Remove", style: .Destructive, handler: { _ in

      let buttonPosition = sender.convertPoint(CGPoint.zero, toView: self.tableView)
      if let indexPath = self.tableView.indexPathForRowAtPoint(buttonPosition) {
        let user = self.collection[indexPath.row]

        if let member = self.storageManager!.getOrganizationMember(user.id) {

          self.storageManager!.deleteOrganizationMember(member.id)
            .onSuccess { _ in
              InAppMessage.showSuccessMessage("Member removed")

              if let userIndex = self.storageManager?.users.indexOf(user) {
                self.storageManager?.users.removeAtIndex(userIndex)
              }
              if let memberIndex = self.storageManager?.members.indexOf(member) {
                self.storageManager?.members.removeAtIndex(memberIndex)
              }
              self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Bottom)
            }.onFailure { _ in
              InAppMessage.showErrorMessage("Something went wrong - Please try again")
          }
        } else {
          fatalError()
        }
      } else {
        fatalError()
      }
    }))

    alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

    self.presentViewController(alertController, animated: true, completion: nil)
  }

  func textFieldShouldReturn(textField: UITextField) -> Bool {
    filterString = nil
    textField.text = ""
    return false
  }

  @IBAction func addMemberFieldChanged(textField: UITextField) {

    if textField.text!.characters.count > 2 && textField.text!.containsString("@") {
      inviteButtonConstraint.priority = UILayoutPriorityDefaultHigh - 1
      self.inviteButton.hidden = false
      UIView.animateWithDuration(0.3) {
        self.view.layoutIfNeeded()
        self.addMemberTextField.layoutIfNeeded()
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

protocol OrganizationCreateDelegate {
  func organizationCreated(organization: Organization)
}
