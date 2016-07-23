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

class StreamTableViewController: UITableViewController {

  var storageManager: OrganizationStorageManager?
  var streamObjects: [StreamObject] = []

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.registerNib(R.nib.streamConversationTableViewCell)
    tableView.registerNib(R.nib.streamAgendaTableViewCell)
    tableView.registerNib(R.nib.streamActionTableViewCell)

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
            switch unseenObject.timeline {
            case let conversation as Conversation:
              streamObject = StreamConversationObject(conversation: conversation)
            case let action as Deliverable:
              var conversationId: String
              if let agendaItemDeliverable = action as? AgendaItemDeliverable {
                let agendaItem = storageManager.agendaItems[agendaItemDeliverable.agendaItemId]!
                conversationId = agendaItem.conversationId
              } else {
                conversationId = action.parentId
              }
              let conversation = storageManager.conversations[conversationId]!
              let author = storageManager.users[action.ownerId]!
              streamObject = StreamActionObject(action: action, conversation: conversation, author: author)
            case let agenda as AgendaItem:
              let conversation = storageManager.conversations[agenda.conversationId]!
              let owner = storageManager.users[agenda.ownerId]!
              streamObject = StreamAgendaObject(agenda: agenda, conversation: conversation, owner: owner)
            default:
              Error.log("unkown timeline \(unseenObject.timeline) for \(unseenObject)")
            }
            next.insert(streamObject!)
          }

          // update last actiondate
          streamObject?.updateLastActionDate(unseenObject.createdAt)

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

    var cell: StreamTableViewCell
    let streamObject = streamObjects[indexPath.row]

    switch streamObject.subject {
    case is Conversation:
      cell = tableView.dequeueReusableCellWithIdentifier(R.nib.streamConversationTableViewCell, forIndexPath: indexPath)!
    case is AgendaItem:
      cell = tableView.dequeueReusableCellWithIdentifier(R.nib.streamAgendaTableViewCell, forIndexPath: indexPath)!
    case is Deliverable:
      cell = tableView.dequeueReusableCellWithIdentifier(R.nib.streamActionTableViewCell, forIndexPath: indexPath)!
    default:
      fatalError("unkown streamobject \(streamObject.subject)")
    }

    cell.streamObject = streamObject

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
