//
//  TimelineTableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 23/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import SlackTextViewController
import DateTools
import ReactiveKit

func == (lhs: TimelineObject, rhs: TimelineObject) -> Bool {
  return lhs.hashValue == rhs.hashValue
}

class TimelineTableViewController: SLKTextViewController {

  var timelineParent: BaseModel!
  var storageManager: OrganizationStorageManager!

  var searchResult: [AnyObject]?

  var editingMessage: Comment?

  let textParser: SizungMarkdownParser = SizungMarkdownParser()

  let collection: CollectionProperty <[TimelineObject]> = CollectionProperty([])
  let sortedCollection: CollectionProperty <[TimelineObject]> = CollectionProperty([])

  var nextPage: Int? = 0

  var mentions = Set<User>()

  var previewFilePath: NSURL?

  let expandingCellTransition = ExpandingCellTransition()
  var selectedIndexPath: NSIndexPath?

  override func viewDidLoad() {
    super.viewDidLoad()

    self.commonInit()
    self.bounces = true

    self.registerPrefixesForAutoCompletion(["@"])
    self.tableView.registerNib(R.nib.commentTableViewCell(), forCellReuseIdentifier: R.nib.commentTableViewCell.identifier )
    self.tableView.registerNib(R.nib.timelineAgendaItemTableViewCell(), forCellReuseIdentifier: R.nib.timelineAgendaItemTableViewCell.identifier )
    self.tableView.registerNib(R.nib.timelineDeliverableTableViewCell(), forCellReuseIdentifier: R.nib.timelineDeliverableTableViewCell.identifier )
    self.tableView.registerNib(R.nib.newMessageSeparatorCell(), forCellReuseIdentifier: R.nib.newMessageSeparatorCell.identifier )
    self.tableView.registerNib(R.nib.attachmentTableViewCell)

    self.autoCompletionView.registerNib(R.nib.autoCompletionTableCell(), forCellReuseIdentifier: R.nib.autoCompletionTableCell.identifier )

    self.textView.registerMarkdownFormattingSymbol("**", withTitle: "Bold")
    self.textView.registerMarkdownFormattingSymbol("*", withTitle: "Italics")

    self.tableView.separatorStyle = .None

    self.tableView.tableFooterView = getFooterView()

    self.initData()
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    // init storagemanager
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.storageManager = storageManager

        // to prevent missing items first connect to websocket, than fetch current state
        StorageManager.sharedInstance.websocket!.conversationWebsocketDelegate = self
        StorageManager.sharedInstance.websocket!.followConversation(self.getConversationId())

        // calculate current unread count for comments
        let lastUnseenMessageDate: NSDate = storageManager.unseenObjects.collection.reduce(NSDate.distantFuture(), combine: { earliestDate, unseenObject in
          var comparisonObject: BaseModel?
          switch self.timelineParent {
          case is Deliverable:
            comparisonObject = storageManager.deliverables[unseenObject.deliverableId]
          case is AgendaItem:
            comparisonObject = storageManager.agendaItems[unseenObject.agendaItemId]
          case is Conversation:
            comparisonObject = storageManager.conversations[unseenObject.conversationId]
          default:
            comparisonObject = nil
          }

          if comparisonObject != nil && comparisonObject == self.timelineParent {
            if unseenObject.createdAt.isEarlierThan(earliestDate) {
              // remove one second to guarantee sort order
              return unseenObject.createdAt.dateByAddingSeconds(-1)
            }
          }
          return earliestDate
        })

        if lastUnseenMessageDate != NSDate.distantFuture() {
          self.collection.insertOrUpdate([TimelineObject(newMessagesDate: lastUnseenMessageDate)])
        }

        // mark unseenObjects as read if not archived

        if self.timelineParent.archived != true {
          storageManager.sawTimeLineFor(self.timelineParent)
        }
    }

    if let selection = self.tableView.indexPathForSelectedRow {
      self.tableView.deselectRowAtIndexPath(selection, animated: true)
    }
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)

    // remove all created unseen objects while view was visible
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.storageManager = storageManager

        if self.timelineParent.archived != true {
          storageManager.sawTimeLineFor(self.timelineParent)
            .onFailure { error in
              InAppMessage.showErrorMessage("There was an error marking everything as seen")
          }
        }
    }

    if let socket = StorageManager.sharedInstance.websocket {
      socket.unfollowConversation(getConversationId())
    }
  }

  override var tableView: UITableView {
    get {
      return super.tableView!
    }
  }

  func getConversationId() -> String {
    switch self.timelineParent {
    case let agendaItem as AgendaItem:
      return agendaItem.conversationId
    case let agendaItemDeliverable as AgendaItemDeliverable:
      return storageManager.agendaItems[agendaItemDeliverable.agendaItemId]!.conversationId
    case let deliverable as Deliverable:
      return deliverable.parentId
    default:
      return timelineParent.id
    }
  }

  func commonInit() {func commonInit() {
    self.transitioningDelegate = expandingCellTransition
    NSNotificationCenter.defaultCenter().addObserver(self.tableView, selector: #selector(UITableView.reloadData), name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }
  }

  func initData() {
    //    sort by date
    collection
      .sort({ $0.sortDate.isLaterThan($1.sortDate)})
      .bindTo(sortedCollection)

    sortedCollection.bindTo(self.tableView) { indexPath, deliverables, tableView in
      if tableView == self.tableView {
        return self.messageCellForRowAtIndexPath(indexPath)
      } else {
        return self.autoCompletionCellForRowAtIndexPath(indexPath)
      }
    }
  }

  func addItemToCollection(item: BaseModel) {
    addItemsToCollection([item])
  }

  func addItemsToCollection(items: [BaseModel]) {

    guard self.timelineParent != nil else {
      fatalError("no timelineparent set ")
    }

    let filteredItems = items
      .filter({ conversationObject in

        // ignore archived objects
        if conversationObject.archived == true {
          return false
        }

        switch conversationObject {
        case let comment as Comment:
          if let commentable = comment.commentable {
            return commentable.id == self.timelineParent.id
          } else {
            Error.log("unknown commentable for comment \(comment.id)")
            return false
          }
        case let deliverable as Deliverable:
          return deliverable.parentId == self.timelineParent.id
        case let agendaItem as AgendaItem:
          return agendaItem.conversationId == self.timelineParent.id
        case let attachment as Attachment:
          return attachment.parentId == self.timelineParent.id
        default:
          return false
        }
      })

    collection.insertOrUpdate(filteredItems.map { baseModel in
      return TimelineObject(model: baseModel)
      })

    // add inset to align rows on top
    let inset = max(self.tableView.frame.height - self.getTableViewContentHeight(), 0)
    self.tableView.contentInset = UIEdgeInsets(top: inset, left: 0, bottom: 0, right: 0)
  }

  func getTableViewContentHeight() -> CGFloat {
    guard collection.count > 0 else {
      return 0
    }
    let lastRowRect = self.tableView.rectForRowAtIndexPath(NSIndexPath(forRow: collection.count-1, inSection: 0))
    return lastRowRect.height + lastRowRect.origin.y
  }

  func didLongPressCell(gesture: UIGestureRecognizer) {

    if gesture.state != .Began {
      return
    }

    self.copyCellMessage(gesture)
  }

  func copyCellMessage(gesture: UIGestureRecognizer) {
    if let cell = gesture.view as? CommentTableViewCell {
      let menuController = UIMenuController.sharedMenuController()
      menuController.setTargetRect(cell.frame, inView: self.tableView)
      menuController.setMenuVisible(true, animated:true)
      cell.becomeFirstResponder()
    }
  }

  func editCellMessage(gesture: UIGestureRecognizer) {
    guard let cell = gesture.view as? CommentTableViewCell else {
      return
    }

    if let indexPath = self.tableView.indexPathForCell(cell) {

      if let comment = sortedCollection[indexPath.row].model as? Comment {
        self.editingMessage = comment
        self.editText(self.editingMessage!.body)
        self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
      }
    }
  }

  // Notifies the view controller when the user has pasted a media (image, video, etc) inside of the text view.
  override func didPasteMediaContent(userInfo: [NSObject : AnyObject]) {

    super.didPasteMediaContent(userInfo)

    let mediaType = userInfo[SLKTextViewPastedItemMediaType]?.integerValue
    let contentType = userInfo[SLKTextViewPastedItemContentType]
    let data = userInfo[SLKTextViewPastedItemData]

    print("didPasteMediaContent : \(contentType) (type = \(mediaType) | data : \(data))")
  }

  // Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
  override func didPressRightButton(sender: AnyObject!) {

    // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
    self.textView.refreshFirstResponder()

    let authToken = AuthToken(data: Configuration.getAuthToken())

    // parse mentions
    var fulltext = self.textView.text

    for (user) in mentions {
      fulltext = fulltext.stringByReplacingOccurrencesOfString("@\(user.name)", withString: "@[\(user.name)](\(user.id))")
    }

    mentions.removeAll()

    let comment = Comment(authorId: authToken.getUserId()!, body: fulltext, commentable: self.timelineParent)

    // push it to server. Ignore result -> will be pushed back over websocket connection
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        storageManager.createComment(comment)
          .onFailure { error in
            let message = "comment creation failed: \(error)"
            Error.log(message)

            InAppMessage.showErrorMessage("There has been an error. Please try again")

            // set message again
            self.textView.text = comment.body
        }
    }

    super.didPressRightButton(sender)
  }

  // Notifies the view controller when a user did shake the device to undo the typed text
  override func willRequestUndo() {
    super.willRequestUndo()
  }

  // Notifies the view controller when tapped on the right "Accept" button for commiting the edited text
  override func didCommitTextEditing(sender: AnyObject) {

    self.editingMessage!.body = self.textView.text
    self.tableView.reloadData()

    super.didCommitTextEditing(sender)
  }

  // Notifies the view controller when tapped on the left "Cancel" button
  override func didCancelTextEditing(sender: AnyObject) {
    super.didCancelTextEditing(sender)
  }

  override func didChangeAutoCompletionPrefix(prefix: String, andWord word: String) {

    var array: [AnyObject]?

    self.searchResult = nil

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.storageManager = storageManager

        if prefix == "@" {

          let conversationUsers = storageManager.users.collection.filter { user in
            if let conversation = self.storageManager.conversations[self.getConversationId()] {
              return conversation.members.contains(user)
            } else {
              Error.log("Conversation not loaded/found")
              return false
            }
          }

          if word.characters.count > 0 {
            array = conversationUsers.filter { user in
              return user.fullName.lowercaseString.containsString(word.lowercaseString)
            }
          } else {
            array = conversationUsers
          }
        }
        var show = false

        if  array?.count > 0 {
          self.searchResult = array
          show = (self.searchResult?.count > 0)
        }

        self.showAutoCompletionView(show)
    }

  }

  override func keyForTextCaching() -> String? {
    return "\(NSBundle.mainBundle().bundleIdentifier)\(self.timelineParent.id)"
  }

  override func heightForAutoCompletionView() -> CGFloat {

    guard let searchResult = self.searchResult else {
      return 0
    }

    let cellHeight = self.autoCompletionView.delegate?.tableView!(self.autoCompletionView, heightForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
    guard let height = cellHeight else {
      return 0
    }
    return height * CGFloat(searchResult.count)
  }

  override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    if indexPath.row >= self.sortedCollection.count - 1 {
      self.updateData()
    }
  }

  func updateData() {

    guard nextPage != nil else {
      return
    }

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        if let nextPage = self.nextPage {
          storageManager.updateConversationObjects(self.timelineParent, page: nextPage)
            .onSuccess { conversationObjects, nextPage in

              // hide top loading view if no further data is available
              if nextPage == nil && self.nextPage > 0 {
                let reachedStartOfConversationView = R.nib.startOfConversationView.firstView(owner: nil)
                reachedStartOfConversationView?.transform = self.tableView.transform
                self.tableView.tableFooterView = reachedStartOfConversationView
              } else if nextPage == nil {
                self.tableView.tableFooterView = nil
              }

              self.nextPage = nextPage
              self.addItemsToCollection(conversationObjects)
          }
        }
    }
  }
}
