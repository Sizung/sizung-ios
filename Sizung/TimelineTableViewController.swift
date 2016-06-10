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

class TimelineTableViewController: SLKTextViewController {
  
  var conversation: Conversation!
  
  var searchResult: [AnyObject]?
  
  var editingMessage : Comment?
  
  let textParser: SizungMarkdownParser = SizungMarkdownParser()
  
  let sortedCollection: CollectionProperty <[BaseModel]> = CollectionProperty([])
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.registerPrefixesForAutoCompletion(["#"])
    self.tableView.registerNib(UINib.init(nibName: "CommentTableViewCell", bundle: nil), forCellReuseIdentifier: "CommentTableViewCell")
    self.initData()
    
    self.tableView.separatorStyle = .None
    
  }
  
  override var tableView: UITableView {
    get {
      return super.tableView!
    }
  }
  
  func initData(){
    StorageManager.sharedInstance.conversationObjects
      //    sort by date
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
    
    StorageManager.sharedInstance.updateConversationObjects(self.conversation.id)
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
    
    let comment = Comment(author: user, body: self.textView.text, commentable: self.conversation)
    //    let indexPath = NSIndexPath(forRow: 0, inSection: 0)
    //    let rowAnimation: UITableViewRowAnimation = self.inverted ? .Bottom : .Top
    //    let scrollPosition: UITableViewScrollPosition = self.inverted ? .Bottom : .Top
    
    // push it to server
    StorageManager.sharedInstance.createComment(comment)
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
  
  override func shouldProcessTextForAutoCompletion(text: String) -> Bool {
    return true
  }
  
  override func didChangeAutoCompletionPrefix(prefix: String, andWord word: String) {
    
    var array: [AnyObject]?
    
    self.searchResult = nil
    
    if prefix == "@" {
      if word.characters.count > 0 {
        array = StorageManager.sharedInstance.organizationUsers.filter { user in
          user.name.hasPrefix(word) || user.email.hasPrefix(word)
        }
      }
      else {
        array = StorageManager.sharedInstance.organizationUsers.collection
      }
    }
    var show = false
    
    if  array?.count > 0 {
      self.searchResult = (array! as NSArray).sortedArrayUsingSelector(#selector(NSString.localizedCaseInsensitiveCompare(_:)))
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
    if !StorageManager.sharedInstance.isInitialized {
      self.updateData()
    }
  }
  
  func updateData(){
    StorageManager.sharedInstance.updateConversationObjects(self.conversation.id)
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
      return StorageManager.sharedInstance.conversationObjects.count
    }
    else {
      if let searchResult = self.searchResult {
        return searchResult.count
      }
    }
    
    return 0
  }
  
  func messageCellForRowAtIndexPath(indexPath: NSIndexPath) -> CommentTableViewCell {
    
    let comment = sortedCollection[indexPath.row] as! Comment
    
    //    switch conversationObject {
    //    case let deliverable as Deliverable:
    //      print("deliverable: \(deliverable.title)")
    //    case let agendaItem as AgendaItem:
    //      print("agendaItem: \(agendaItem.title)")
    //    case let comment as Comment:
    //      print("comment: \(comment.body)")
    
    let cell = tableView.dequeueReusableCellWithIdentifier("CommentTableViewCell") as! CommentTableViewCell
    
    cell.bodyLabel.attributedText = textParser.parseMarkdown(comment.body)
    cell.bodyLabel.textColor = (comment.offline ? UIColor.grayColor() : UIColor.blackColor())
    cell.datetimeLabel.text = comment.created_at?.timeAgoSinceNow()
    
    let author = StorageManager.sharedInstance.getUser(comment.author.id)!
    
    let gravatar = Gravatar(emailAddress: author.email, defaultImage: .MysteryMan)
    cell.configureCellWithURLString(gravatar.URL(size: cell.bounds.width).URLString)
    
    if cell.gestureRecognizers?.count == nil {
      let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.didLongPressCell(_:)))
      cell.addGestureRecognizer(longPress)
    }
    
    
    // Cells must inherit the table view's transform
    // This is very important, since the main table view may be inverted
    cell.transform = self.tableView.transform
    
    return cell
    //    }
    //
    //    return cell
  }
  
  func autoCompletionCellForRowAtIndexPath(indexPath: NSIndexPath) -> CommentTableViewCell {
    
    let cell = self.autoCompletionView.dequeueReusableCellWithIdentifier("AutoCompletionTableCell") as! CommentTableViewCell
    cell.selectionStyle = .Default
    
    guard let searchResult = self.searchResult as? [String] else {
      return cell
    }
    
    guard let prefix = self.foundPrefix else {
      return cell
    }
    
    var text = searchResult[indexPath.row]
    
    if prefix == "#" {
      text = "# " + text
    }
    else if prefix == ":" || prefix == "+:" {
      text = ":\(text):"
    }
    
    cell.bodyLabel.text = text
    
    return cell
  }
  
  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    
    if tableView == self.tableView {
      let comment = sortedCollection[indexPath.row] as! Comment
      
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineBreakMode = .ByWordWrapping
      paragraphStyle.alignment = .Left
      
      let attributes = [
        NSParagraphStyleAttributeName : paragraphStyle
      ]
      
      var width = CGRectGetWidth(tableView.frame)-50
      width -= 25.0
      
      guard let author = StorageManager.sharedInstance.getUser(comment.author!.id) else {
        return 0
      }
      
      let titleBounds = (author.name).boundingRectWithSize(CGSize(width: width, height: CGFloat.max), options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)
      let bodyBounds = (comment.body!).boundingRectWithSize(CGSize(width: width, height: CGFloat.max), options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)
      
      if comment.body!.characters.count == 0 {
        return 0
      }
      
      var height = CGRectGetHeight(titleBounds)
      height += CGRectGetHeight(bodyBounds)
      height += 40
      
      if height < CommentTableViewCell.kMinimumHeight {
        height = CommentTableViewCell.kMinimumHeight
      }
      
      return height
    }
    else {
      return CommentTableViewCell.kMinimumHeight
    }
  }
  
  // MARK: - UITableViewDelegate Methods
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    if tableView == self.autoCompletionView {
      
      guard let searchResult = self.searchResult as? [String] else {
        return
      }
      
      var item = searchResult[indexPath.row]
      
      if self.foundPrefix == "@" && self.foundPrefixRange.location == 0 {
        item += ":"
      }
      else if self.foundPrefix == ":" || self.foundPrefix == "+:" {
        item += ":"
      }
      
      item += " "
      
      self.acceptAutoCompletionWithString(item, keepPrefix: true)
    }
  }
}

