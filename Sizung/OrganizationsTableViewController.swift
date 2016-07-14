//
//  OrganizationsTableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 21/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import ReactiveKit
import ReactiveUIKit

class OrganizationsTableViewController: UITableViewController {

  let organizations: CollectionProperty <[Organization]> = CollectionProperty([])

  override func viewDidLoad() {
    super.viewDidLoad()

    self.refreshControl?.addTarget(
      self, action:
      #selector(self.updateData),
      forControlEvents: UIControlEvents.ValueChanged
    )
    self.tableView.registerNib(
      R.nib.organizationTableViewCell(),
      forCellReuseIdentifier: R.nib.organizationTableViewCell.identifier
    )

    self.initData()
  }

  func initData() {
    organizations.bindTo(self.tableView) { indexPath, organizations, tableView in
      if let cell = tableView.dequeueReusableCellWithIdentifier(
        R.nib.organizationTableViewCell.identifier,
        forIndexPath: indexPath
        ) as? OrganizationTableViewCell {
        let organization = organizations[indexPath.row]
        cell.nameLabel.text = organization.name

        let unseenObjects = StorageManager.sharedInstance.unseenObjects
        let hasUnseenObject = unseenObjects.collection.contains { obj in
          return obj.organizationId == organization.id
        }

        cell.unreadStatusView.alpha = hasUnseenObject ? 1 : 0
        return cell
      } else {
        fatalError("Unexpected cell type")
      }
    }
  }

  override func viewDidAppear(animated: Bool) {
    updateData()
  }

  func updateData() {
    self.refreshControl?.beginRefreshing()
    StorageManager.sharedInstance.listOrganizations()
      .onSuccess { organizations in
        self.organizations.replace(organizations, performDiff: true)
      }.onFailure { error in
        let message = "\(error)"
        Error.log(message)
      }.onComplete { _ in
        self.refreshControl?.endRefreshing()
    }
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let selectedOrganization = organizations[indexPath.row]

    if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
      appDelegate.switchToOrganization(selectedOrganization.id)
    }

    self.dismissViewControllerAnimated(true, completion: nil)
  }
}
