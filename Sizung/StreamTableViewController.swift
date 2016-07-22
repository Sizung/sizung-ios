//
//  StreamTableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 15/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import ReactiveKit
import Rswift

class StreamObject: Hashable, Equatable, DateSortable {
  let subject: BaseModel!

  var mentioners: Set<User.UserId>! = []
  var commenters: Set<User.UserId>! = []

  init(subject: BaseModel) {
    self.subject = subject
  }

  var sortDate: NSDate {
    get {
      return subject.createdAt
    }
  }

  var hashValue: Int {
    get {
      return subject.id.hashValue
    }
  }
}

func == (lhs: StreamObject, rhs: StreamObject) -> Bool {
  return lhs.subject.id == rhs.subject.id
}

class StreamTableViewController: UITableViewController {

  var storageManager: OrganizationStorageManager?
  var streamObjects: [StreamObject] = []

  override func viewDidLoad() {
    super.viewDidLoad()

    self.tableView.registerNib(R.nib.streamTableViewCell)

    StorageManager.sharedInstance.unseenObjects.observeNext { _ in
      self.updateData()
    }.disposeIn(rBag)

    updateData()


    self.tableView.tableFooterView?.hidden = true
  }

  func updateData() {

    let userId = AuthToken(
      data: Configuration.getAuthToken()).getUserId()!

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.storageManager = storageManager

        // filter for subscribed unseenObjects in the selected organizations
        let subscribedObjects = StorageManager.sharedInstance.unseenObjects.collection.filter { unseenObject in
          return unseenObject.subscribed && unseenObject.organizationId == Configuration.getSelectedOrganization()
          }

        let streamSet = subscribedObjects.reduce(Set<StreamObject>([])) { prev, unseenObject in

          var next = prev

          var streamObject = prev.filter { $0.subject.id == unseenObject.timelineId }.first

          if streamObject == nil {
            streamObject = StreamObject(subject: unseenObject.timeline)
            next.insert(streamObject!)
          }

          switch unseenObject.target {
          case let comment as Comment:
            // comments
            streamObject?.commenters.insert(comment.authorId)

            // mentions
            if comment.body.containsString(userId) {
              streamObject?.mentioners.insert(comment.authorId)
            }
          default:
            Error.log("unkown target: \(unseenObject.target) for unseenObject \(unseenObject)")
          }

          if let comment = unseenObject.target as? Comment {


          }

          return next
        }

        self.streamObjects = streamSet.sort { $0.0.sortDate.isLaterThan($0.1.sortDate)}

        self.tableView.reloadData()

        self.tableView.tableFooterView?.hidden = self.streamObjects.count > 0
    }
  }

  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return streamObjects.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

    let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.streamTableViewCell, forIndexPath: indexPath)!
    cell.streamObject = streamObjects[indexPath.row]
    return cell
  }

  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 100
  }
}
