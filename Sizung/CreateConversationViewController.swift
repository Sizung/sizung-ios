//
//  CreateConversationViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 17/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class CreateConversationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

  @IBOutlet weak var conversationNameTextField: UITextField!
  @IBOutlet weak var tableView: UITableView!

  var conversation = Conversation(organizationId: Configuration.getSelectedOrganization()!)

  override func viewDidLoad() {
    super.viewDidLoad()

    self.tableView.registerNib(R.nib.memberTableViewCell)

    // add the current user
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        let authToken = AuthToken(data: Configuration.getAuthToken())
        let user = storageManager.users[authToken.getUserId()!]!
        self.conversation.members.append(user)
    }


    // Do any additional setup after loading the view.
  }

  @IBAction func close(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }

  @IBAction func save(sender: AnyObject) {

    // save conversation

//    self.dismissViewControllerAnimated(true, completion: nil)
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.memberTableViewCell.identifier, forIndexPath: indexPath) as? MemberTableViewCell {

      let user = self.conversation.members[indexPath.row]

      cell.avatarImage.user = user
      cell.nameLabel.text = "\(user.firstName) \(user.lastName)"

      cell.deleteButton.tag = indexPath.row
      cell.deleteButton.addTarget(self, action: #selector(removeMember), forControlEvents: .TouchUpInside)

      return cell
    } else {
      fatalError()
    }
  }

  func removeMember(sender: UIButton) {
    let indexPath = NSIndexPath(forRow: sender.tag, inSection: 0)
    self.conversation.members.removeAtIndex(indexPath.row)
    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
  }

  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.conversation.members.count
  }



  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
   // Get the new view controller using segue.destinationViewController.
   // Pass the selected object to the new view controller.
   }
   */

}
