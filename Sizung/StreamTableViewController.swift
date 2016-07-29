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
  var filteredUnseenObjectsDisposable: Disposable? = nil
  var streamObjects = CollectionProperty<Array<StreamObject>>([])

  var finishedLoading = false

  var showUnsubscribedGestureRecognizer: UITapGestureRecognizer?

  @IBOutlet weak var loadingView: UIStackView!
  @IBOutlet weak var logoView: UIImageView!
  @IBOutlet weak var emptyView: UIStackView!
  @IBOutlet weak var unseenObjectsLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.registerNib(R.nib.streamConversationTableViewCell)
    tableView.registerNib(R.nib.streamAgendaTableViewCell)
    tableView.registerNib(R.nib.streamActionTableViewCell)

    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 100

    showUnsubscribedGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.showUnsubscribed))

    initData()

    self.refreshControl?.addTarget(
      self,
      action: #selector(self.updateData),
      forControlEvents: UIControlEvents.ValueChanged
    )
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

    self.logoView.alpha = 0.2

    UIView.animateWithDuration(
      1.5,
      delay: 0.5,
      options: [ .Repeat, .CurveLinear, .Autoreverse],
      animations: {
        self.logoView.alpha = 1
      }, completion: nil)
  }

  // see http://collindonnell.com/2015/09/29/dynamically-sized-table-view-header-or-footer-using-auto-layout/
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    // Dynamic sizing for the footer view
    if let footerview = tableView.tableFooterView {
      let height = self.tableView.frame.height
      var footerFrame = footerview.frame

      // If we don't have this check, viewDidLayoutSubviews() will get
      // repeatedly, causing the app to hang.
      if height != footerFrame.size.height {
        footerFrame.size.height = height
        footerview.frame = footerFrame
        tableView.tableFooterView = footerview
      }
    }
  }

  func initData() {
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.storageManager = storageManager

        self.filteredUnseenObjects.observeNext { diff in

          let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
          dispatch_async(dispatch_get_global_queue(priority, 0)) {

            let reducedStreamObjects = self.filteredUnseenObjects.collection.reduce([], combine: self.reduceUnseenObjectsToStreamObjects)

            let sortedObjects = reducedStreamObjects.sort {
              $0.0.sortDate.isLaterThan($0.1.sortDate)
            }

            self.streamObjects.replace(sortedObjects, performDiff: true)

            dispatch_async(dispatch_get_main_queue()) {
              self.hideLoadingView()
            }
          }
        }.disposeIn(self.rBag)

        self.streamObjects.bindTo(self.tableView, animated: true, createCell: self.cellForRow)

        self.showSubscribed()
        self.updateData()
    }
  }

  func updateData() {
    showSubscribed()
    self.finishedLoading = false
    self.fetchUnseenObjectsPage(0, subscribed: true)
  }

  func fetchUnseenObjectsPage(page: Int, subscribed: Bool) {
    if let orgId = Configuration.getSelectedOrganization() {
      storageManager!.listUnseenObjectsForOrganization(subscribed, orgId: orgId, page: page)
        .onSuccess { unseenObjectsResponse in

          if let nextPage = unseenObjectsResponse.nextPage {
            self.fetchUnseenObjectsPage(nextPage, subscribed: subscribed)
          } else {
            if subscribed {
              self.finishedLoading = true

              // load all unsubscribed objects
              self.fetchUnseenObjectsPage(0, subscribed: false)
            }
            self.hideLoadingView()
          }
      }
    }
  }

  func hideLoadingView() {
    self.tableView.tableFooterView?.hidden = self.streamObjects.count > 0
    if self.finishedLoading {
      self.refreshControl?.endRefreshing()
      self.logoView.stopAnimating()
      UIView.animateWithDuration(0.5) {
        self.loadingView.alpha = 0
        self.emptyView.alpha = 1

//        var unseenObjectText: String
        if let unseenCount = self.storageManager?.unseenObjects.count {
          if unseenCount > 0 {
            //            unseenObjectText = "You have read your subscriptions.\nBut there is still something you haven't seen\n\nTouch here to show."
            self.emptyView.userInteractionEnabled = true
            self.emptyView.addGestureRecognizer(self.showUnsubscribedGestureRecognizer!)
          } else {
//            unseenObjectText = "You’re all caught up.\n\nEat a cupcake!"
            self.emptyView.userInteractionEnabled = false
            self.emptyView.removeGestureRecognizer(self.showUnsubscribedGestureRecognizer!)
          }

          self.unseenObjectsLabel.text = "You’re all caught up.\n\nEat a cupcake!"

        }
      }
    }
  }

  func showSubscribed() {
    self.filteredUnseenObjectsDisposable?.dispose()
    // filter for subscribed unseenObjects in the selected organizations
    self.filteredUnseenObjectsDisposable = storageManager!.unseenObjects.filter { unseenObject in
      return unseenObject.subscribed && unseenObject.organizationId == Configuration.getSelectedOrganization()
      }.bindTo(self.filteredUnseenObjects)
  }

  func showUnsubscribed() {
    self.filteredUnseenObjectsDisposable?.dispose()
    // filter for subscribed unseenObjects in the selected organizations
    self.filteredUnseenObjectsDisposable = storageManager!.unseenObjects.filter { unseenObject in
      return unseenObject.organizationId == Configuration.getSelectedOrganization()
      }.bindTo(self.filteredUnseenObjects)
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

    self.fillFromTarget(streamObject!, unseenObject: unseenObject)

    return next
  }

  func fillFromTarget(streamObject: StreamObject, unseenObject: UnseenObject) {
    switch unseenObject.target {
    case let comment as Comment:
      if let user = storageManager!.users[comment.authorId] {
        // comments
        streamObject.commentAuthors.insert(user)

        // mentions
        if comment.body.containsString(userId) {
          streamObject.mentionAuthors.insert(user)
        }
      }
    case is Conversation:
      // don't handle Conversations
      break
    case is AgendaItem:
      // don't handle Agendas
      break
    case is Deliverable:
      // don't handle Deliverables
      break
    case is Attachment:
      // don't handle attachments
      break
    default:
      Error.log("unkown target: \(unseenObject.target) for unseenObject \(unseenObject)")
    }
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
