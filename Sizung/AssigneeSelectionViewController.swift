//
//  AssigneeSelectionViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 18/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class AssigneeSelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

  @IBOutlet weak var searchField: UITextField!
  @IBOutlet weak var searchContainer: UIView!
  @IBOutlet weak var tableView: UITableView!

  var delegate: AssigneeSelectedDelegate?

  var conversation: Conversation?

  var storageManager: OrganizationStorageManager?

  var filterString: String?

  var collection: [User] = []

  override func viewDidLoad() {
    super.viewDidLoad()

    self.searchContainer.layer.borderColor = UIColor.lightGrayColor().CGColor
    self.searchContainer.layer.borderWidth = 1

    self.tableView.registerNib(R.nib.memberTableViewCell)

    self.searchField.delegate = self
    searchField.becomeFirstResponder()

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.storageManager = storageManager

        self.updateTableView()
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
      cell.deleteButton.hidden = true

      return cell
    } else {
      fatalError()
    }
  }

  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    delegate?.assigneeSelected(self.collection[indexPath.row])
  }

  @IBAction func addMemberFieldChanged(textField: UITextField) {

    filterString = textField.text
    if filterString?.characters.count == 0 {
      filterString = nil
    }
    updateTableView()
  }

  func updateTableView() {
    self.collection = storageManager!.users.collection.filter { user in
      return (self.conversation?.members.contains(user))!
    }

    if let filterString = self.filterString {
      self.collection = self.collection.filter { user in
        return user.fullName.lowercaseString.containsString(filterString.lowercaseString)
      }
    }

    self.tableView.reloadData()
  }

}

protocol AssigneeSelectedDelegate {
  func assigneeSelected(assignee: User)
}
