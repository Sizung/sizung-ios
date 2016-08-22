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
import MRProgress

class StreamTableViewController: UITableViewController {

  var storageManager: OrganizationStorageManager?
  let userId = AuthToken(data: Configuration.getSessionToken()).getUserId()!

  var filteredUnseenObjects = CollectionProperty<Array<UnseenObject>>([])
  var filteredUnseenObjectsDisposable: Disposable? = nil
  var streamObjects: [StreamObject] = []

  var finishedLoading = false

  @IBOutlet weak var loadingView: UIStackView!
  @IBOutlet weak var logoView: UIImageView!
  @IBOutlet weak var emptyView: UIStackView!
  @IBOutlet weak var unseenObjectsLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.registerNib(R.nib.streamConversationTableViewCell)
    tableView.registerNib(R.nib.streamAgendaTableViewCell)
    tableView.registerNib(R.nib.streamActionTableViewCell)
    tableView.registerNib(R.nib.streamDateTableViewCell)

    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 100

    initData()

    self.refreshControl?.addTarget(
      self,
      action: #selector(self.updateData),
      forControlEvents: UIControlEvents.ValueChanged
    )

    self.tableView.backgroundView = self.tableView.tableFooterView
    self.tableView.tableFooterView = nil
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

  func initData() {
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.storageManager = storageManager

        self.filteredUnseenObjects.observeNext { diff in

          let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
          dispatch_async(dispatch_get_global_queue(priority, 0)) {

            let reducedStreamObjects: Dictionary<String, StreamObject> = self.filteredUnseenObjects.collection.reduce([:], combine: self.reduceUnseenObjectsToStreamObjects)

            // calculate days
            let daySet: Set<StreamObject> = Set(reducedStreamObjects.map { (timeLineId, streamObject) in
              return StreamDateObject(date: streamObject.sortDate)
              })

            // merge day seperator objects and streamobjects
            let streamAndDayObjects = daySet.union(reducedStreamObjects.values)

            let sortedObjects = streamAndDayObjects.sort {
              $0.0.sortDate.isLaterThan($0.1.sortDate)
            }

            self.streamObjects = sortedObjects

            dispatch_async(dispatch_get_main_queue()) {
              self.tableView.reloadData()
              self.hideLoadingView()
            }
          }
          }.disposeIn(self.rBag)

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

            // hide/update loadingview if not subsribed
            if !subscribed {
              self.hideLoadingView()
            }
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

    self.unseenObjectsLabel.hidden = self.streamObjects.count > 0

    if self.finishedLoading {
      self.refreshControl?.endRefreshing()
      self.logoView.stopAnimating()

      UIView.animateWithDuration(0.5) {
        self.loadingView.alpha = 0
        self.emptyView.alpha = 1
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

  func reduceUnseenObjectsToStreamObjects(prev: Dictionary<String, StreamBaseObject>, unseenObject: UnseenObject) -> Dictionary<String, StreamBaseObject> {
    var next = prev

    var streamObject = prev[unseenObject.timelineId!]

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

      next[unseenObject.timelineId!] = streamObject
    }

    // update last actiondate
    streamObject?.updateLastActionDate(unseenObject.createdAt)

    self.fillFromTarget(streamObject!, unseenObject: unseenObject)

    return next
  }

  func fillFromTarget(streamObject: StreamBaseObject, unseenObject: UnseenObject) {
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

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return streamObjects.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

    let streamObject = streamObjects[indexPath.row]

    switch streamObject {
    case is StreamDateObject:
      let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.streamDateTableViewCell, forIndexPath: indexPath)!
      cell.setDate(streamObject.date)

      return cell
    case let streamBaseObject as StreamBaseObject:

      var cell: StreamTableViewCell

      switch streamBaseObject.subject {
      case is Conversation:
        cell = tableView.dequeueReusableCellWithIdentifier(R.nib.streamConversationTableViewCell, forIndexPath: indexPath)!
      case is AgendaItem:
        cell = tableView.dequeueReusableCellWithIdentifier(R.nib.streamAgendaTableViewCell, forIndexPath: indexPath)!
      case is Deliverable:
        cell = tableView.dequeueReusableCellWithIdentifier(R.nib.streamActionTableViewCell, forIndexPath: indexPath)!
      default:
        fatalError("unkown streamobject \(streamBaseObject.subject)")
      }
      cell.streamObject = streamBaseObject

      return cell

    default:
      fatalError("unkown type: \(streamObject.dynamicType)")
    }
  }

  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    switch self.streamObjects[indexPath.row] {
    case is StreamDateObject:
      return 44
    default:
      return UITableViewAutomaticDimension
    }
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    guard indexPath.row < self.streamObjects.count else {
      Error.log("Index out of range \(indexPath.row)/\(self.streamObjects.count)")
      return
    }

    let streamObject = self.streamObjects[indexPath.row]

    guard let streamBaseObject = streamObject as? StreamBaseObject else {
      return
    }

    let cell = self.tableView.cellForRowAtIndexPath(indexPath)

    MRProgressOverlayView.showOverlayAddedTo(cell, animated: true)

    func errorFunc(error: StorageError) {
      InAppMessage.showErrorMessage("There was a problem loading your unseen object. Please try again")
      MRProgressOverlayView.dismissOverlayForView(cell, animated: true)
    }


    switch streamBaseObject.subject {
    case let conversation as Conversation:
      MRProgressOverlayView.dismissOverlayForView(cell, animated: true)
      self.openViewControllerFor(nil, inConversation: conversation)
    case let agendaItem as AgendaItem:
      StorageManager.sharedInstance.getConversation(agendaItem.conversationId).onComplete {test in print("")}
        .onSuccess { conversation in
          self.openViewControllerFor(agendaItem, inConversation: conversation)
        }.onFailure(callback: errorFunc)
        .onComplete(callback: { _ in MRProgressOverlayView.dismissOverlayForView(cell, animated: true)})
    case let agendaItemDeliverable as AgendaItemDeliverable:
      StorageManager.sharedInstance.getAgendaItem(agendaItemDeliverable.agendaItemId)
        .onSuccess { agendaItem in
          StorageManager.sharedInstance.getConversation(agendaItem.conversationId)
            .onSuccess { conversation in
              self.openViewControllerFor(agendaItemDeliverable, inConversation: conversation)
            }.onFailure(callback: errorFunc)
            .onComplete(callback: { _ in MRProgressOverlayView.dismissOverlayForView(cell, animated: true)})
        }.onFailure(callback: errorFunc)
    case let deliverable as Deliverable:
      StorageManager.sharedInstance.getConversation(deliverable.parentId)
        .onSuccess { conversation in
          self.openViewControllerFor(deliverable, inConversation: conversation)
        }.onFailure(callback: errorFunc)
        .onComplete(callback: { _ in MRProgressOverlayView.dismissOverlayForView(cell, animated: true)})

    default:
      fatalError()
    }
  }

  func openViewControllerFor(item: BaseModel?, inConversation conversation: Conversation) {
    let conversationController = R.storyboard.conversation.initialViewController()!
    conversationController.conversation = conversation
    conversationController.openItem = item

    self.presentViewController(conversationController, animated: true, completion: nil)
  }
}
