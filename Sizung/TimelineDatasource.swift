//
//  TimelineDatasource.swift
//  Sizung
//
//  Created by Markus Klepp on 05/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
// for direct s3 download
import Alamofire
import MRProgress

extension TimelineTableViewController: ExpandingTransitionPresentingViewController {

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

      if deliverable.dueOn != nil && !deliverable.isCompleted() {
        cell.dueDateLabel.text = DueDateHelper.getDueDateString(deliverable.dueOn!)
      } else {
        cell.dueDateLabel.text = ""
      }

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

        self.showViewController(agendaItemViewController, fromFrame: tableView.rectForRowAtIndexPath(indexPath))
      case let deliverable as Deliverable:
        let deliverableViewController = R.storyboard.deliverable.initialViewController()!
        deliverableViewController.deliverable = deliverable

        if deliverable is AgendaItemDeliverable {
          self.navigationController?.pushViewController(deliverableViewController, animated: true)
        } else {
          self.showViewController(deliverableViewController, fromFrame: tableView.rectForRowAtIndexPath(indexPath))
        }
      case let attachment as Attachment:
        self.loadAttachment(attachment)
      case is Comment:
        // don't react to comment clicks
        break
      default:
        fatalError("unkown row at didSelectRowAtIndexPath \(indexPath)")
      }
    }
  }

  func loadAttachment(attachment: Attachment) {
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

          self.showPreview()
        }
        MRProgressOverlayView.dismissOverlayForView(self.view, animated: true)
    }
    // display a stop button for large files
    if attachment.fileSize > 10*1024*1024 {
      progressView.stopBlock = { progressOverlayView in
        request.cancel()
      }
    }
  }

  func showViewController(viewController: UIViewController, fromFrame frame: CGRect) {

    let transition = CATransition()
    transition.duration = 0.3
    transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    transition.type = kCATransitionPush
    transition.subtype = kCATransitionFromTop
    self.navigationController?.view.layer.addAnimation(transition, forKey: nil)

    self.navigationController?.pushViewController(viewController, animated: false)
  }

  // MARK: ExpandingTransitionPresentingViewController

  func expandingTransitionTargetViewForTransition(transition: ExpandingCellTransition) -> UIView! {
    if let indexPath = selectedIndexPath {
      return tableView.cellForRowAtIndexPath(indexPath)
    } else {
      return nil
    }
  }
}
