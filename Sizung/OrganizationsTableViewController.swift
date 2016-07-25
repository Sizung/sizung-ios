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
  var unseenObjects: Set<UnseenObject> = []

  var organizationTableViewDelegate: OrganizationTableViewDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    self.refreshControl?.addTarget(
      self, action:
      #selector(self.updateData),
      forControlEvents: UIControlEvents.ValueChanged
    )

    self.refreshControl?.tintColor = UIColor.whiteColor()

    self.tableView.registerNib(
      R.nib.organizationTableViewCell(),
      forCellReuseIdentifier: R.nib.organizationTableViewCell.identifier
    )

    self.initData()
  }

  func initData() {

    self.tableView.contentOffset = CGPoint(x: 0, y: -self.refreshControl!.frame.size.height)
    self.refreshControl?.beginRefreshing()

    organizations.bindTo(self.tableView) { indexPath, organizations, tableView in
      if let cell = tableView.dequeueReusableCellWithIdentifier(
        R.nib.organizationTableViewCell.identifier,
        forIndexPath: indexPath
        ) as? OrganizationTableViewCell {
        let organization = organizations[indexPath.row]
        cell.nameLabel.text = organization.name

        let hasUnseenObject = self.unseenObjects.contains { obj in
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
    StorageManager.sharedInstance.listOrganizations()
      .onSuccess { organizations in

        // query unseenObjects
        self.fetchUnseenObjectsPage(0)

        self.organizations.replace(organizations, performDiff: true)
      }.onFailure { error in
        let message = "\(error)"
        Error.log(message)
      }.onComplete { _ in
        self.refreshControl?.endRefreshing()
    }
  }

  func fetchUnseenObjectsPage(page: Int) {
    if let userId = AuthToken(data: Configuration.getAuthToken()).getUserId() {
      StorageManager.sharedInstance.listUnseenObjectsForUser(userId, page: page)
        .onSuccess { unseenObjectsResponse in
          self.unseenObjects.unionInPlace(unseenObjectsResponse.unseenObjects)
          if let nextPage = unseenObjectsResponse.nextPage {
            self.fetchUnseenObjectsPage(nextPage)
            self.tableView.reloadData()
          } else {
            self.tableView.reloadData()
          }
      }
    }
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let selectedOrganization = organizations[indexPath.row]
    organizationTableViewDelegate?.organizationSelected(selectedOrganization)
  }
}

protocol OrganizationTableViewDelegate {
  func organizationSelected(organization: Organization)
}
