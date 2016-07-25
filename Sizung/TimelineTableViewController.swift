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
import Alamofire
import AlamofireImage
import MRProgress
import QuickLook

class TimelineObject: Hashable, DateSortable {
  let model: BaseModel?
  let newMessagesDate: NSDate?

  init(model: BaseModel) {
    self.model = model
    self.newMessagesDate = nil
  }

  init(newMessagesDate: NSDate) {
    self.newMessagesDate = newMessagesDate
    self.model = nil
  }

  var hashValue: Int {
    get {
      if let hashValue = model?.hashValue {
        return hashValue
      } else if let hashValue = newMessagesDate?.hashValue {
        return hashValue
      } else {
        return 0
      }
    }
  }

  var sortDate: NSDate {
    get {
      if let date = model?.sortDate {
        return date
      } else {
        return newMessagesDate!
      }
    }
  }
}

func == (lhs: TimelineObject, rhs: TimelineObject) -> Bool {
  return lhs.hashValue == rhs.hashValue
}

class TimelineTableViewController: SLKTextViewController, WebsocketDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource {

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

        // mark unseenObjects as read
        storageManager.sawTimeLineFor(self.timelineParent)
          .onFailure { error in
            InAppMessage.showErrorMessage("There was an error marking everything as seen")
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
        storageManager.sawTimeLineFor(self.timelineParent)
          .onFailure { error in
            InAppMessage.showErrorMessage("There was an error marking everything as seen")
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

    NSNotificationCenter.defaultCenter().addObserver(self.tableView, selector: #selector(UITableView.reloadData), name: UIContentSizeCategoryDidChangeNotification, object: nil)
    //    NSNotificationCenter.defaultCenter().addObserver(self,  selector: #selector(self.textInputbarDidMove(_:)), name: SLKTextInputbarDidMoveNotification, object: nil)

    // Register a SLKTextView subclass, if you need any special appearance and/or behavior customisation.
    //    self.registerClassForTextView(MessageTextView.classForCoder())
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

  func onConnectFailed() {
    InAppMessage.showErrorMessage("There has been an error connecting to this Timeline")
  }

  func onDisconnected() {
    InAppMessage.showErrorMessage("You have been disconnected from this Timeline")
  }

  func onFollowSuccess(itemId: String) {
    self.updateData()
  }

  func onReceived(conversationObject: BaseModel) {
    addItemToCollection(conversationObject)
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
    guard let cell = gesture.view as? CommentTableViewCell else {
      return
    }

    if let indexPath = self.tableView.indexPathForCell(cell) {

      if let comment = sortedCollection[indexPath.row].model as? Comment {
        UIPasteboard.generalPasteboard().string = comment.body
      }
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
    //    let indexPath = NSIndexPath(forRow: 0, inSection: 0)
    //    let rowAnimation: UITableViewRowAnimation = self.inverted ? .Bottom : .Top
    //    let scrollPosition: UITableViewScrollPosition = self.inverted ? .Bottom : .Top

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
    //
    //    self.tableView.beginUpdates()
    //    StorageManager.sharedInstance.conversationObjects.insert(comment, atIndex: 0)
    //    self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: rowAnimation)
    //    self.tableView.endUpdates()

    //    self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: scrollPosition, animated: true)

    // Fixes the cell from blinking (because of the transform, when using translucent cells)
    // See https://github.com/slackhq/SlackTextViewController/issues/94#issuecomment-69929927
    //    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

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
              return user.name.lowercaseString.hasPrefix(word.lowercaseString)
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


  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

  }
}

extension TimelineTableViewController {

  // MARK: - UITableViewDataSource Methods

  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

    if tableView == self.autoCompletionView {
      if let searchResult = self.searchResult {
        return searchResult.count
      }
    }

    return 0
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    if tableView == self.autoCompletionView {
      return self.autoCompletionCellForRowAtIndexPath(indexPath)
    } else {
      fatalError("unkown tableview in cellForRowAtIndexPath")
    }
  }

  func getFooterView() -> UIView {
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    activityIndicator.transform = self.tableView.transform
    activityIndicator.startAnimating()

    return activityIndicator
  }

  func messageCellForRowAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell {

    var cell: UITableViewCell

    switch sortedCollection[indexPath.row].model {
    case let deliverable as Deliverable:
      cell = self.cellForDeliverable(deliverable)
    case let agendaItem as AgendaItem:
      cell = self.cellForAgendaItem(agendaItem)
    case let comment as Comment:
      cell = self.cellForComment(comment)
    case let attachment as Attachment:
      cell = self.cellForAttachment(attachment)
    default:
      if sortedCollection[indexPath.row].newMessagesDate != nil {
        cell = self.cellForNewMessageSeparator()
      } else {
        fatalError("unkown row type for \(self)")
      }
    }

    // Cells must inherit the table view's transform
    // This is very important, since the main table view may be inverted
    cell.transform = self.tableView.transform

    cell.backgroundColor = UIColor.clearColor()

    return cell
  }

  func cellForNewMessageSeparator() -> UITableViewCell {
    return tableView.dequeueReusableCellWithIdentifier(R.nib.newMessageSeparatorCell.identifier)!
  }

  func cellForDeliverable(deliverable: Deliverable) -> TimelineDeliverableTableViewCell {
    if let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.timelineDeliverableTableViewCell.identifier) as? TimelineDeliverableTableViewCell {

      cell.titleLabel.setTitle(deliverable.title, forState: .Normal)
      cell.dueDateLabel.text = deliverable.dueOn?.timeAgoSinceNow()
      cell.dateLabel.text = deliverable.createdAt?.timeAgoSinceNow()

      if let author = storageManager.users[deliverable.ownerId] {
        cell.authorImage.user = author
      }

      if let assignee = storageManager.users[deliverable.assigneeId] {
        cell.assigneeImage.user = assignee
      }

      return cell
    } else {
      fatalError("unexpected cell type")
    }
  }

  func cellForAgendaItem(agendaItem: AgendaItem) -> TimelineAgendaItemTableViewCell {
    if let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.timelineAgendaItemTableViewCell.identifier) as? TimelineAgendaItemTableViewCell {

      cell.titleLabel.setTitle(agendaItem.title, forState: .Normal)
      cell.dateLabel.text = agendaItem.createdAt?.timeAgoSinceNow()

      if let author = storageManager.users[agendaItem.ownerId] {
        cell.authorImage.user = author
      }

      return cell
    } else {
      fatalError("unexpected cell type")
    }
  }

  func cellForAttachment(attachment: Attachment) -> AttachmentTableViewCell {
    if let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.attachmentTableViewCell.identifier) as? AttachmentTableViewCell {

      cell.setAttachment(attachment)

      return cell

    } else {
      fatalError()
    }
  }

  func cellForComment(comment: Comment) -> CommentTableViewCell {
    if let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.commentTableViewCell.identifier) as? CommentTableViewCell {

      cell.bodyLabel.setText(textParser.parseMarkdown(comment.body))
      cell.bodyLabel.textColor = (comment.offline ? UIColor.grayColor() : UIColor.blackColor())
      cell.datetimeLabel.text = comment.createdAt?.timeAgoSinceNow()

      if let author = storageManager.users[comment.authorId] {
        cell.authorImage.user = author
      }

      if cell.gestureRecognizers?.count == nil {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.didLongPressCell(_:)))
        cell.addGestureRecognizer(longPress)
      }

      cell.selectionStyle = .None

      return cell

    } else {
      fatalError("unexpected cell type")
    }
  }

  func autoCompletionCellForRowAtIndexPath(indexPath: NSIndexPath) -> AutoCompletionTableCell {

    if let cell = self.autoCompletionView.dequeueReusableCellWithIdentifier(R.nib.autoCompletionTableCell.identifier) as? AutoCompletionTableCell {
      cell.selectionStyle = .Default

      guard let searchResult = self.searchResult as? [User] else {
        return cell
      }

      let user = searchResult[indexPath.row]

      cell.usernameLabel.text = user.name

      cell.userImage.user = user

      return cell
    } else {
      fatalError("unexpected cell type")
    }
  }

  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

    if tableView == self.tableView {
      switch sortedCollection[indexPath.row].model {
      case _ as Comment:
        return UITableViewAutomaticDimension
      case _ as AgendaItem:
        return TimelineAgendaItemTableViewCell.kHeight
      case let deliverable as Deliverable where deliverable.dueOn != nil:
        return TimelineDeliverableTableViewCell.kHeight
      case _ as Deliverable:
        return TimelineDeliverableTableViewCell.kHeightWithoutDueDate
      default:
        return UITableViewAutomaticDimension
      }
    } else {
      return AutoCompletionTableCell.kMinimumHeight
    }
  }

  override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    if tableView == self.tableView {
      switch sortedCollection[indexPath.row].model {
      case _ as Comment:
        return CommentTableViewCell.kMinimumHeight
      case _ as AgendaItem:
        return TimelineAgendaItemTableViewCell.kHeight
      case let deliverable as Deliverable where deliverable.dueOn != nil:
        return TimelineDeliverableTableViewCell.kHeight
      case _ as Deliverable:
        return TimelineDeliverableTableViewCell.kHeightWithoutDueDate
      case is Attachment:
        return 20
      default:
        return self.tableView.rowHeight
      }
    } else {
      return AutoCompletionTableCell.kMinimumHeight
    }
  }

  // MARK: - UITableViewDelegate Methods

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    if tableView == self.autoCompletionView {

      guard let searchResult = self.searchResult as? [User] else {
        return
      }

      let user = searchResult[indexPath.row]

      var text = ""

      if self.foundPrefix == "@" {
        text += user.name
        mentions.insert(user)
      }

      self.acceptAutoCompletionWithString(text)
    } else {
      switch sortedCollection[indexPath.row].model {
      case let agendaItem as AgendaItem:

        let agendaItemViewController = R.storyboard.agendaItem.initialViewController()!
        agendaItemViewController.agendaItem = agendaItem

        self.navigationController?.pushViewController(agendaItemViewController, animated: true)
      case let deliverable as Deliverable:
        let deliverableViewController = R.storyboard.deliverable.initialViewController()!
        deliverableViewController.deliverable = deliverable

        self.navigationController?.pushViewController(deliverableViewController, animated: true)
      case let attachment as Attachment:
        var localPath: NSURL?

        let progressView = MRProgressOverlayView.showOverlayAddedTo(self.view, animated: true)
        progressView.mode = .DeterminateCircular

        let request = Alamofire.download(.GET, attachment.fileUrl,
          destination: { (temporaryURL, response) in
            let tempPath = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]

            let subFolder = tempPath.URLByAppendingPathComponent(attachment.id, isDirectory: true)

            do {
              try NSFileManager.defaultManager().createDirectoryAtURL(subFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
              fatalError()
            }

            localPath = subFolder.URLByAppendingPathComponent(attachment.fileName)

            return localPath!
        })
          .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
            let progress = Float(totalBytesRead)/Float(totalBytesExpectedToRead)
            progressView.setProgress(progress, animated: true)
          }
          .response { (request, response, _, error) in
            if let localPath = localPath {

              self.previewFilePath = localPath

              let previewController = QLPreviewController()
              previewController.dataSource = self
              self.presentViewController(previewController, animated: true, completion: nil)
            }
            MRProgressOverlayView.dismissOverlayForView(self.view, animated: true)
        }
        // display a stop button for large files
        if attachment.fileSize > 10*1024*1024 {
          progressView.stopBlock = { progressOverlayView in
            request.cancel()
          }
        }


      case is Comment:
        // don't react to comment clicks
        break
      default:
        fatalError("unkown row at didSelectRowAtIndexPath \(indexPath)")
      }
    }
  }

  func numberOfPreviewItemsInPreviewController(controller: QLPreviewController) -> Int {
    return 1
  }

  func previewController(controller: QLPreviewController, previewItemAtIndex index: Int) -> QLPreviewItem {
    return previewFilePath!
  }

}
