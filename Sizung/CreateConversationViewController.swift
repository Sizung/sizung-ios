//
//  CreateConversationViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 17/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class CreateConversationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

  @IBOutlet weak var conversationNameTextField: UITextField!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var addMemberContainer: UIView!

  private var conversation = Conversation(organizationId: Configuration.getSelectedOrganization()!)

  var storageManager: OrganizationStorageManager?

  var filterString: String?

  var possibleMembers: [User] {
    get {
      let diff = Set(storageManager!.users.collection).subtract(conversation.members)
      if let filterString = filterString {
        return Array(diff).filter { user in
          return user.firstName.containsString(filterString) || user.lastName.containsString(filterString)
        }
      } else {
        return Array(diff)
      }
    }
  }

  var addMode = false

  var collection: [User] {
    get {
      if addMode {
        return possibleMembers
      } else {
        return conversation.members
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
        let authToken = AuthToken(data: Configuration.getAuthToken())
        let user = storageManager.users[authToken.getUserId()!]!

        self.conversation.members.append(user)
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

      if self.conversation.members.contains(user) {
        cell.deleteButton.hidden = false
        cell.deleteButton.tag = indexPath.row
        cell.deleteButton.addTarget(self, action: #selector(self.removeMember), forControlEvents: .TouchUpInside)
      } else {
        cell.deleteButton.hidden = true
      }

      return cell
    } else {
      fatalError()
    }
  }

  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    self.conversation.members.append(collection[indexPath.row])
    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
  }

  @IBAction func close(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }

  @IBAction func save(sender: AnyObject) {

    // save conversation

//    self.dismissViewControllerAnimated(true, completion: nil)
  }

  func removeMember(sender: UIButton) {
    let indexPath = NSIndexPath(forRow: sender.tag, inSection: 0)
    self.conversation.members.removeAtIndex(indexPath.row)
    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Bottom)
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
    print("add")
    filterString = nil
    textField.text = ""
    return false
  }

  @IBAction func addMemberFieldChanged(textField: UITextField) {

    filterString = textField.text
    if filterString?.characters.count == 0 {
      filterString = nil
    }
    self.tableView.reloadData()
  }


}
