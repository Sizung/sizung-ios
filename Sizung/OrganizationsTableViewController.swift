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

struct OrganizationListModel: Equatable, Hashable {
  let organization: Organization
  var sortOrder: Int

  var hashValue: Int { return organization.hashValue }
}

func == (lhs: OrganizationListModel, rhs: OrganizationListModel) -> Bool {
  return lhs.organization.id == rhs.organization.id
}

func > (lhs: OrganizationListModel, rhs: OrganizationListModel) -> Bool {
  return lhs.sortOrder > rhs.sortOrder
}

class OrganizationsTableViewController: UITableViewController {

  var disposable: Disposable?
  let unsortedOrganizations: CollectionProperty <[OrganizationListModel]> = CollectionProperty([])
  let organizations: CollectionProperty <[OrganizationListModel]> = CollectionProperty([])
  var unseenObjects: Set<UnseenObject> = []

  var organizationTableViewDelegate: OrganizationTableViewDelegate?

  var dragView: UIView? = nil
  var dragSourceIndexPath: NSIndexPath? = nil

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

    self.unsortedOrganizations.sort(>).bindTo(self.organizations)

    organizations.bindTo(self.tableView) { indexPath, organizationListModels, tableView in
      if let cell = tableView.dequeueReusableCellWithIdentifier(
        R.nib.organizationTableViewCell.identifier,
        forIndexPath: indexPath
        ) as? OrganizationTableViewCell {
        let organization = organizationListModels[indexPath.row].organization
        cell.nameLabel.text = organization.name

        let hasUnseenObject = self.unseenObjects.contains { obj in
          return obj.organizationId == organization.id
        }

        cell.unreadStatusView.alpha = hasUnseenObject ? 1 : 0

        cell.editButton.tag = indexPath.row
        cell.editButton.addTarget(self, action: #selector(self.editOrganization(_:)), forControlEvents: .TouchUpInside)

        if self.dragSourceIndexPath == indexPath {
          cell.hidden = true
        } else {
          cell.hidden = false
        }

        return cell
      } else {
        fatalError("Unexpected cell type")
      }
    }

    // init reorder
    let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGestureRecognized(_:)))
    self.tableView.addGestureRecognizer(longPressRecognizer)
  }

  override func viewDidAppear(animated: Bool) {
    updateData()
  }

  func editOrganization(sender: UIButton) {
    let indexPath = NSIndexPath(forRow: sender.tag, inSection: 0)
    let organization = self.organizations[indexPath.row].organization

    let createOrganizationViewController = R.storyboard.organizations.create()!
    createOrganizationViewController.organization = organization
    presentViewController(createOrganizationViewController, animated: true, completion: nil)
  }

  func updateData() {
    StorageManager.sharedInstance.listOrganizations()
      .onSuccess { organizations in

        // query unseenObjects
        self.fetchUnseenObjectsPage(0)

        let organizationListModels = organizations.enumerate().map { (index, organization) in
          return OrganizationListModel(organization: organization, sortOrder: index)
        }

        self.unsortedOrganizations.replace(organizationListModels, performDiff: true)

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

  override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let selectedOrganization = organizations[indexPath.row].organization
    organizationTableViewDelegate?.organizationSelected(selectedOrganization)
  }

  func longPressGestureRecognized(recognizer: UILongPressGestureRecognizer) {
    let state = recognizer.state

    let location = recognizer.locationInView(self.tableView)

    if let indexPath = self.tableView.indexPathForRowAtPoint(location) {

    switch state {
    case .Began:

      if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {

        self.dragSourceIndexPath = indexPath

        let dragView = cell.snapshotViewAfterScreenUpdates(false)

        dragView.center = cell.center
        dragView.alpha = 0.0
        self.tableView.addSubview(dragView)
        self.dragView = dragView

        UIView.animateWithDuration(0.25, animations: {
          dragView.center = CGPoint(x: cell.center.x, y: location.y)
          dragView.transform = CGAffineTransformMakeScale(1.1, 1.1)
          dragView.alpha = 0.5

          // Fade out.
          cell.alpha = 0.0
          }, completion: { _ in cell.hidden = true})
      }

    case .Changed:

      if let dragView = self.dragView {
        dragView.center = CGPoint(x: dragView.center.x, y: location.y)
      }

      if indexPath != self.dragSourceIndexPath, let dragSourceIndexPath = self.dragSourceIndexPath {

        var draggedOrganization = self.organizations[dragSourceIndexPath.row]
        let draggedOrder = draggedOrganization.sortOrder

        var currentPosOrganization = self.organizations[indexPath.row]
        draggedOrganization.sortOrder = currentPosOrganization.sortOrder
        currentPosOrganization.sortOrder = draggedOrder

        // set before actual update
        self.dragSourceIndexPath = indexPath
        self.organizations.moveItemAtIndex(dragSourceIndexPath.row, toIndex: indexPath.row)
      }

    default:

      if let cell = self.tableView.cellForRowAtIndexPath(self.dragSourceIndexPath!) {
        cell.alpha = 0
        cell.hidden = false
        UIView.animateWithDuration(0.25, animations: {
          self.dragView?.center = cell.center
          self.dragView?.transform = CGAffineTransformIdentity
          self.dragView?.alpha = 0

          cell.alpha = 1
          }, completion: { _ in
            self.dragSourceIndexPath = nil
            self.dragView?.removeFromSuperview()
            self.dragView = nil
        })
      }
    }
    }
  }
}

protocol OrganizationTableViewDelegate {
  func organizationSelected(organization: Organization)
}
