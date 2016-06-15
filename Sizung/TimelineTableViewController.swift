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

class TimelineTableViewController: SLKTextViewController, ConversationWebsocketDelegate {
  
  var conversation: Conversation!
  var timelineParent: BaseModel!
  
  var searchResult: [AnyObject]?
  
  var editingMessage : Comment?
  
  let textParser: SizungMarkdownParser = SizungMarkdownParser()
  
  let collection: CollectionProperty <[BaseModel]> = CollectionProperty([])
  let sortedCollection: CollectionProperty <[BaseModel]> = CollectionProperty([])
  
  //  var mentions: [(Range<String.Index>, User)] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.commonInit()
    
    self.bounces = true
    
    self.registerPrefixesForAutoCompletion(["@"])
    self.tableView.registerNib(UINib.init(nibName: "CommentTableViewCell", bundle: nil), forCellReuseIdentifier: "CommentTableViewCell")
    self.tableView.registerNib(UINib.init(nibName: "TimelineDeliverableTableViewCell", bundle: nil), forCellReuseIdentifier: "TimelineDeliverableTableViewCell")
    self.tableView.registerNib(UINib.init(nibName: "TimelineAgendaItemTableViewCell", bundle: nil), forCellReuseIdentifier: "TimelineAgendaItemTableViewCell")
    self.autoCompletionView.registerNib(UINib.init(nibName: "AutoCompletionTableCell", bundle: nil), forCellReuseIdentifier: "AutoCompletionTableCell")
    
    self.textView.registerMarkdownFormattingSymbol("**", withTitle: "Bold")
    self.textView.registerMarkdownFormattingSymbol("*", withTitle: "Italics")
    
    self.tableView.separatorStyle = .None
    
    self.initData()
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    // to prevent missing items first connect to websocket, than fetch current state
    StorageManager.sharedInstance.websocket!.conversationWebsocketDelegate = self
    StorageManager.sharedInstance.websocket!.followConversation(self.conversation.id)
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    
    StorageManager.sharedInstance.websocket!.unfollowConversation(self.conversation.id)
  }
  
  override var tableView: UITableView {
    get {
      return super.tableView!
    }
  }
  
  func commonInit(){func commonInit() {
    
    NSNotificationCenter.defaultCenter().addObserver(self.tableView, selector: #selector(UITableView.reloadData), name: UIContentSizeCategoryDidChangeNotification, object: nil)
    //    NSNotificationCenter.defaultCenter().addObserver(self,  selector: #selector(self.textInputbarDidMove(_:)), name: SLKTextInputbarDidMoveNotification, object: nil)
    
    // Register a SLKTextView subclass, if you need any special appearance and/or behavior customisation.
    //    self.registerClassForTextView(MessageTextView.classForCoder())
    }
  }
  
  func initData(){
    //    sort by date
    collection
      .sort({ $0.created_at!.compare($1.created_at!) == NSComparisonResult.OrderedDescending })
      .bindTo(sortedCollection)
    
    sortedCollection.bindTo(self.tableView) { indexPath, deliverables, tableView in
      if tableView == self.tableView {
        return self.messageCellForRowAtIndexPath(indexPath)
      }
      else {
        return self.autoCompletionCellForRowAtIndexPath(indexPath)
      }
    }
  }
  
  func onFollowSuccess(id: String) {
    print("Following conversation \(id)")
    self.updateData()
  }
  
  func onReceived(conversationObject: BaseModel) {
    addItemToCollection(conversationObject)
  }
  
  func addItemToCollection(item: BaseModel) {
    addItemsToCollection([item])
  }
  
  func addItemsToCollection(items: [BaseModel]) {
    let filteredItems = items
      .filter({ conversationObject in
        switch conversationObject{
        case let comment as Comment:
          return comment.commentable.id == self.timelineParent.id
        case let deliverable as Deliverable:
          return deliverable.conversation.id == self.timelineParent.id
        case let agendaItem as AgendaItem:
          return agendaItem.conversation.id == self.timelineParent.id
        default:
          return false
        }
      })
    
    collection.insertOrUpdate(filteredItems)
  }
  
  func didLongPressCell(gesture: UIGestureRecognizer) {
    
    if gesture.state != .Began {
      return
    }
    
    self.editCellMessage(gesture)
  }
  
  func editCellMessage(gesture: UIGestureRecognizer) {
    guard let cell = gesture.view as? CommentTableViewCell else {
      return
    }
    
    if let indexPath = self.tableView.indexPathForCell(cell) {
      
      self.editingMessage = sortedCollection[indexPath.row] as? Comment
      self.editText(self.editingMessage!.body)
      
      self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
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
    
    let authToken = AuthToken(data: KeychainWrapper.stringForKey(Configuration.Settings.AUTH_TOKEN))
    let user = User(id: authToken.getUserId()!)
    
    // parse mentions
    let fulltext = self.textView.text
    
    //    for (range, user) in mentions {
    //      fulltext.replaceRange(range, with: "@[\(user.name)](\(user.id))")
    //    }
    //
    //    mentions = []
    
    let comment = Comment(author: user, body: fulltext, commentable: self.timelineParent)
    //    let indexPath = NSIndexPath(forRow: 0, inSection: 0)
    //    let rowAnimation: UITableViewRowAnimation = self.inverted ? .Bottom : .Top
    //    let scrollPosition: UITableViewScrollPosition = self.inverted ? .Bottom : .Top
    
    // push it to server. Ignore result -> will be pushed over websocket connection
    StorageManager.sharedInstance.createComment(comment)
      .onSuccess { comment in
        print("Comment successfully created")
      } .onFailure { error in
        print("Comment creation failed: \(error)")
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
    
    if prefix == "@" {
      if word.characters.count > 0 {
        array = StorageManager.sharedInstance.organizationUsers.filter { user in
          return user.name.lowercaseString.hasPrefix(word.lowercaseString)
        }
      }
      else {
        array = StorageManager.sharedInstance.organizationUsers.collection
      }
    }
    var show = false
    
    if  array?.count > 0 {
      self.searchResult = array
      show = (self.searchResult?.count > 0)
    }
    
    self.showAutoCompletionView(show)
  }
  
  
  override func keyForTextCaching() -> String? {
    
    return NSBundle.mainBundle().bundleIdentifier
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
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    if !StorageManager.sharedInstance.isInitialized {
      self.updateData()
    }
  }
  
  func updateData(){
    StorageManager.sharedInstance.updateConversationObjects(self.timelineParent)
      .onSuccess { conversationObjects in
        self.addItemsToCollection(conversationObjects)
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
    
    if tableView == self.tableView {
      return sortedCollection.count
    }
    else {
      if let searchResult = self.searchResult {
        return searchResult.count
      }
    }
    
    return 0
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    if tableView == self.autoCompletionView {
      return self.autoCompletionCellForRowAtIndexPath(indexPath)
    }else {
      fatalError("unkown tableview in cellForRowAtIndexPath")
    }
  }
  
  func messageCellForRowAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell {
    
    var cell: UITableViewCell
    
    switch sortedCollection[indexPath.row] {
    case let deliverable as Deliverable:
      cell = self.cellForDeliverable(deliverable)
    case let agendaItem as AgendaItem:
      cell = self.cellForAgendaItem(agendaItem)
    case let comment as Comment:
      cell = self.cellForComment(comment)
    default:
      fatalError("unkown row type for \(self)")
    }
    
    // Cells must inherit the table view's transform
    // This is very important, since the main table view may be inverted
    cell.transform = self.tableView.transform
    
    
    return cell
  }
  
  func cellForDeliverable(deliverable: Deliverable) -> TimelineDeliverableTableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("TimelineDeliverableTableViewCell") as! TimelineDeliverableTableViewCell
    
    cell.titleLabel.text = deliverable.title
    cell.dueDateLabel.text = deliverable.due_on?.timeAgoSinceNow()
    cell.dateLabel.text = deliverable.created_at?.timeAgoSinceNow()
    
    if let author = StorageManager.sharedInstance.getUser(deliverable.owner.id) {
      let authorGravatar = Gravatar(emailAddress: author.email, defaultImage: .Identicon)
      cell.configureAuthorImageWithURLString(authorGravatar.URL(size: cell.bounds.width).URLString)
    }
    
    if let assignee = StorageManager.sharedInstance.getUser(deliverable.assignee.id) {
      let assigneeGravatar = Gravatar(emailAddress: assignee.email, defaultImage: .Identicon)
      cell.configureAssigneeImageWithURLString(assigneeGravatar.URL(size: cell.bounds.width).URLString)
    }
    
    return cell
  }
  
  func cellForAgendaItem(agendaItem: AgendaItem) -> TimelineAgendaItemTableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("TimelineAgendaItemTableViewCell") as! TimelineAgendaItemTableViewCell
    
    cell.titleLabel.text = agendaItem.title
    cell.dateLabel.text = agendaItem.created_at?.timeAgoSinceNow()
    
    if let author = StorageManager.sharedInstance.getUser(agendaItem.owner.id) {
      
      let gravatar = Gravatar(emailAddress: author.email, defaultImage: .Identicon)
      cell.configureCellWithURLString(gravatar.URL(size: cell.bounds.width).URLString)
    }
    
    return cell
  }
  
  func cellForComment(comment: Comment) -> CommentTableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("CommentTableViewCell") as! CommentTableViewCell
    
    cell.bodyLabel.attributedText = textParser.parseMarkdown(comment.body)
    cell.bodyLabel.textColor = (comment.offline ? UIColor.grayColor() : UIColor.blackColor())
    cell.datetimeLabel.text = comment.created_at?.timeAgoSinceNow()
    
    if let author = StorageManager.sharedInstance.getUser(comment.author.id) {
      let gravatar = Gravatar(emailAddress: author.email, defaultImage: .Identicon)
      cell.configureCellWithURLString(gravatar.URL(size: cell.bounds.width).URLString)
    }
    
    //    if cell.gestureRecognizers?.count == nil {
    //      let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.didLongPressCell(_:)))
    //      cell.addGestureRecognizer(longPress)
    //    }
    
    cell.selectionStyle = .None
    
    return cell
  }
  
  func autoCompletionCellForRowAtIndexPath(indexPath: NSIndexPath) -> AutoCompletionTableCell {
    
    let cell = self.autoCompletionView.dequeueReusableCellWithIdentifier("AutoCompletionTableCell") as! AutoCompletionTableCell
    cell.selectionStyle = .Default
    
    guard let searchResult = self.searchResult as? [User] else {
      return cell
    }
    
    let user = searchResult[indexPath.row]
    
    cell.usernameLabel.text = user.name
    
    let gravatar = Gravatar(emailAddress: user.email, defaultImage: .Identicon)
    cell.configureCellWithURLString(gravatar.URL(size: cell.bounds.width).URLString)
    
    return cell
  }
  
  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    
    if tableView == self.tableView {
      switch sortedCollection[indexPath.row] {
      case let comment as Comment:
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .ByWordWrapping
        paragraphStyle.alignment = .Left
        
        var width = CGRectGetWidth(tableView.frame)-50
        width -= 25.0
        
        //      guard let author = StorageManager.sharedInstance.getUser(comment.author!.id) else {
        //        return 0
        //      }
        
        //      let titleBounds = (author.name).boundingRectWithSize(CGSize(width: width, height: CGFloat.max), options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)
        let bodyBounds = textParser.parseMarkdown(comment.body).boundingRectWithSize(CGSize(width: width, height: CGFloat.max), options: .UsesLineFragmentOrigin, context: nil)
        let datetimeBounds = textParser.parseMarkdown("singleline").boundingRectWithSize(CGSize(width: width, height: CGFloat.max), options: .UsesLineFragmentOrigin, context: nil)
        
        if comment.body!.characters.count == 0 {
          return 0
        }
        
        //      var height = CGRectGetHeight(titleBounds)
        var height = CGRectGetHeight(bodyBounds)
        height += CGRectGetHeight(datetimeBounds)
        height += 24
        
        if height < CommentTableViewCell.kMinimumHeight {
          height = CommentTableViewCell.kMinimumHeight
        }
        
        return height
      case _ as AgendaItem:
        return TimelineAgendaItemTableViewCell.kHeight
      case let deliverable as Deliverable where deliverable.due_on != nil:
        return TimelineDeliverableTableViewCell.kHeight
      case _ as Deliverable:
        return TimelineDeliverableTableViewCell.kHeightWithoutDueDate
      default:
        return 0;
      }
    }
    else {
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
        text += "@[\(user.name)](\(user.id)) "
        
        //        let range = self.textView.text.startIndex.advancedBy(self.foundPrefixRange.location)..<self.textView.text.startIndex.advancedBy(self.foundPrefixRange.location + text.characters.count + self.foundPrefixRange.length)
        //
        //        mentions.append((range, user))
      }
      
      
      self.acceptAutoCompletionWithString(text, keepPrefix: false)
    } else {
      switch sortedCollection[indexPath.row]{
      case let agendaItem as AgendaItem:
        
        let agendaItemViewController = UIStoryboard(name: "AgendaItem", bundle: nil).instantiateInitialViewController() as! AgendaItemViewController
        agendaItemViewController.agendaItem = agendaItem
        
        self.showViewController(agendaItemViewController, sender: self)
      case let deliverable as Deliverable:
        let deliverableViewController = UIStoryboard(name: "Deliverable", bundle: nil).instantiateInitialViewController() as! DeliverableViewController
        deliverableViewController.deliverable = deliverable
        
        self.showViewController(deliverableViewController, sender: self)
      case let comment as Comment:
        print("selected comment \(comment)")
      default:
        fatalError("unkown row at didSelectRowAtIndexPath \(indexPath)")
      }
    }
  }
}

