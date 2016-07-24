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
  let userId = AuthToken(data: Configuration.getAuthToken()).getUserId()!

  var filteredUnseenObjects = CollectionProperty<Array<UnseenObject>>([])
  var streamObjects = CollectionProperty<Array<StreamObject>>([])

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.registerNib(R.nib.streamConversationTableViewCell)
    tableView.registerNib(R.nib.streamAgendaTableViewCell)
    tableView.registerNib(R.nib.streamActionTableViewCell)

    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 100

    initData()

    self.refreshControl?.addTarget(
      self,
      action: #selector(self.updateData),
      forControlEvents: UIControlEvents.ValueChanged
    )

    self.tableView.tableFooterView?.hidden = true
  }

  func initData() {

    // filter for subscribed unseenObjects in the selected organizations
    StorageManager.sharedInstance.unseenObjects.filter { unseenObject in
      return unseenObject.subscribed && unseenObject.organizationId == Configuration.getSelectedOrganization()
      }.bindTo(self.filteredUnseenObjects)

    self.filteredUnseenObjects.observeNext { _ in

      let reducedStreamObjects = self.filteredUnseenObjects.collection.reduce([], combine: self.reduceUnseenObjectsToStreamObjects)

      let sortedObjects = reducedStreamObjects.sort {
        $0.0.sortDate.isLaterThan($0.1.sortDate)
        }

      self.streamObjects.replace(sortedObjects, performDiff: true)

    }.disposeIn(rBag)


    self.streamObjects.bindTo(self.tableView, animated: true, createCell: self.cellForRow)


    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.storageManager = storageManager
        self.updateData()
    }
  }

  func updateData() {
    self.refreshControl?.beginRefreshing()
    self.fetchUnseenObjectsPage(0)
  }

  func fetchUnseenObjectsPage(page: Int) {
    if let userId = AuthToken(data: Configuration.getAuthToken()).getUserId() {
      StorageManager.sharedInstance.listUnseenObjects(userId, page: page)
        .onSuccess { unseenObjectsResponse in

          if let nextPage = unseenObjectsResponse.nextPage {
            self.fetchUnseenObjectsPage(nextPage)
          } else {
            print("\(self.streamObjects.count)/\(StorageManager.sharedInstance.unseenObjects.count)")
            self.tableView.tableFooterView?.hidden = self.streamObjects.count > 0
            self.refreshControl?.endRefreshing()
          }
      }
    }
  }

  func reduceUnseenObjectsToStreamObjects(prev: [StreamObject], unseenObject: UnseenObject) -> [StreamObject] {
    var next = prev

    var streamObject = prev.filter { streamObject in
      return streamObject.subject.id == unseenObject.timelineId
      }.first

    if streamObject == nil {
      switch unseenObject.timeline {
      case let conversation as Conversation:
        streamObject = StreamConversationObject(conversation: conversation)
      case let agendaItemAction as AgendaItemDeliverable:
        let agendaItem = self.storageManager!.agendaItems[agendaItemAction.agendaItemId]!
        let conversation = self.storageManager!.conversations[agendaItem.conversationId]!
        let author = self.storageManager!.users[agendaItemAction.ownerId]!
        streamObject = StreamActionObject(action: agendaItemAction, conversation: conversation, author: author)
      case let action as Deliverable:
        let conversation = self.storageManager!.conversations[action.parentId]!
        let author = self.storageManager!.users[action.ownerId]!
        streamObject = StreamActionObject(action: action, conversation: conversation, author: author)
      case let agenda as AgendaItem:
        let conversation = self.storageManager!.conversations[agenda.conversationId]!
        let owner = self.storageManager!.users[agenda.ownerId]!
        streamObject = StreamAgendaObject(agenda: agenda, conversation: conversation, owner: owner)
      default:
        Error.log("unkown timeline \(unseenObject.timeline) for \(unseenObject)")
        return next
      }

      next.append(streamObject!)
    }

    // update last actiondate
    streamObject?.updateLastActionDate(unseenObject.createdAt)

    switch unseenObject.target {
    case let comment as Comment:
      if let user = storageManager!.users[comment.authorId] {
        // comments
        streamObject?.commentAuthors.insert(user)

        // mentions
        if comment.body.containsString(userId) {
          streamObject?.mentionAuthors.insert(user)
        }
      }
//    case let attachment as Attachment:
    default:
      Error.log("unkown target: \(unseenObject.target) for unseenObject \(unseenObject)")
    }

    return next
  }

  func cellForRow(indexPath: NSIndexPath, streamObjects: [StreamObject], tableView: UITableView) -> UITableViewCell {

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
    let streamObject = self.streamObjects[indexPath.row]

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
