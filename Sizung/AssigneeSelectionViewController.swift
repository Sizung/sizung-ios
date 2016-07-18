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
      cell.nameLabel.text = "\(user.firstName) \(user.lastName)"
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
        return user.firstName.containsString(filterString) || user.lastName.containsString(filterString)
      }
    }

    self.tableView.reloadData()
  }

}

protocol AssigneeSelectedDelegate {
  func assigneeSelected(assignee: User)
}
