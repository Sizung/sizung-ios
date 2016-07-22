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

  var mentionAuthors: Set<User>! = []
  var commentAuthors: Set<User>! = []

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

    tableView.registerNib(R.nib.streamTableViewCell)
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 100

    StorageManager.sharedInstance.unseenObjects.observeNext { _ in
      self.updateData()
      }.disposeIn(rBag)

    updateData()

    self.refreshControl?.addTarget(
      self,
      action: #selector(self.updateData),
      forControlEvents: UIControlEvents.ValueChanged
    )

    self.tableView.tableFooterView?.hidden = true
  }

  func updateData() {

    self.refreshControl?.beginRefreshing()

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
            if let user = storageManager.users[comment.authorId] {
              // comments
              streamObject?.commentAuthors.insert(user)

              // mentions
              if comment.body.containsString(userId) {
                streamObject?.mentionAuthors.insert(user)
              }
            }
          default:
            Error.log("unkown target: \(unseenObject.target) for unseenObject \(unseenObject)")
          }

          return next
        }

        self.streamObjects = streamSet.sort { $0.0.sortDate.isLaterThan($0.1.sortDate)}

        self.tableView.reloadData()

        self.tableView.tableFooterView?.hidden = self.streamObjects.count > 0


        self.refreshControl?.endRefreshing()
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

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let streamObject = streamObjects[indexPath.row]

    switch streamObject.subject {
    case let conversation as Conversation:
      self.openViewControllerFor(nil, inConversation: conversation)
    case let agendaItem as AgendaItem:
      StorageManager.sharedInstance.getConversation(agendaItem.conversationId)
        .onSuccess { conversation in
          self.openViewControllerFor(agendaItem, inConversation: conversation)
      }
    case let agendaItemDeliverable as AgendaItemDeliverable:
      StorageManager.sharedInstance.getAgendaItem(agendaItemDeliverable.agendaItemId)
        .onSuccess { agendaItem in
          StorageManager.sharedInstance.getConversation(agendaItem.conversationId)
            .onSuccess { conversation in
              self.openViewControllerFor(agendaItemDeliverable, inConversation: conversation)
          }
      }
    case let deliverable as Deliverable:
      StorageManager.sharedInstance.getConversation(deliverable.parentId)
        .onSuccess { conversation in
          self.openViewControllerFor(deliverable, inConversation: conversation)
      }


    default:
      fatalError()
    }
  }

  func openViewControllerFor(item: BaseModel?, inConversation conversation: Conversation) {
    let conversationController = R.storyboard.conversation.initialViewController()!
    conversationController.conversation = conversation
    conversationController.openItem = item

    self.showViewController(conversationController, sender: nil)
  }
}
