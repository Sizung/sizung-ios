//
//  ConversationsTableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 21/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import ReactiveKit
import ReactiveUIKit
import SwiftKeychainWrapper

class ConversationsTableViewController: UITableViewController, ConversationCreateDelegate {

  var filterDisposable: Disposable?

  let sortedCollection: CollectionProperty <[Conversation]> = CollectionProperty([])
  let filteredCollection: CollectionProperty <[Conversation]> = CollectionProperty([])

  var delegate: ConversationTableViewDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    self.refreshControl?.addTarget(
      self,
      action: #selector(self.updateData),
      forControlEvents: UIControlEvents.ValueChanged
    )
    self.tableView.registerNib(R.nib.conversationTableViewCell)

    self.initData()
  }

  func initData() {

    StorageManager.storageForSelectedOrganization().onSuccess { storageManager in

      // listen to unseenObject changes
      storageManager.unseenObjects.observeNext { _ in
        self.tableView.reloadData()
        }.disposeIn(self.rBag)

      storageManager.conversations.sort { left, right in
        return left.title.compare(right.title) == .OrderedAscending
        }.bindTo(self.sortedCollection)

      self.filterFor("")

      self.filteredCollection.bindTo(self.tableView, animated: true) { indexPath, conversations, tableView in
        if let cell = tableView.dequeueReusableCellWithIdentifier(
          R.nib.conversationTableViewCell.identifier,
          forIndexPath: indexPath)
          as? ConversationTableViewCell {
          let conversation = conversations[indexPath.row]
          cell.nameLabel.text = conversation.title

          let activeUsersCount = conversation.members.reduce(0, combine: {sum, user in
            if let user = storageManager.users[user.id] {
              return sum + (user.isActive() ? 1 : 0)
            } else {
              return sum
            }
          })


          cell.activeCountLabel.text = "\(activeUsersCount) active"
          // clear containerview
          cell.activeImageViewsContainerView.subviews.forEach({$0.removeFromSuperview()})

          var currentPos: CGFloat = 0

          conversation.members.forEach { user in
            if let user = storageManager.users[user.id] {

              guard user.isActive() else {
                return
              }

              let imageWidth = cell.activeImageViewsContainerView.frame.height

              let imageView = AvatarImageView()
              imageView.frame = CGRect(x: currentPos, y: 0, width: imageWidth, height: imageWidth)
              cell.activeImageViewsContainerView.addSubview(imageView)
              imageView.user = user

              currentPos += imageWidth
            }
          }

          let unseenObjects = storageManager.unseenObjects

          let hasUnseenObject = unseenObjects.collection.contains { obj in
            return obj.conversationId == conversation.id
          }

          cell.unreadStatusView.alpha = hasUnseenObject ? 1 : 0

          return cell
        } else {
          fatalError("Unknown cell type for \(self.dynamicType)")
        }
      }
    }

    filteredCollection.observeNext { _ in
      self.tableView.tableFooterView?.hidden = self.filteredCollection.count > 0
    }.disposeIn(rBag)
  }

  func filterFor(filterString: String) {
    filterDisposable?.dispose()

    filterDisposable = sortedCollection.filter { conversation in
      if filterString.isEmpty {
        return true
      } else {
        return conversation.title.lowercaseString.containsString(filterString.lowercaseString)
      }
    }.bindTo(filteredCollection)
  }

  func updateData() {

    self.refreshControl?.beginRefreshing()

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        storageManager.listConversations()
          .onComplete { _ in
            self.refreshControl?.endRefreshing()
        }
    }
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let selectedConversation = sortedCollection[indexPath.row]
    delegate?.conversationSelected(selectedConversation)
  }

  @IBAction func tableFooterClicked(sender: AnyObject) {
    let createConversationViewController = R.storyboard.conversations.create()!
    createConversationViewController.delegate = self
    self.presentViewController(createConversationViewController, animated: true, completion: nil)
  }

  func conversationCreated(conversation: Conversation) {
    delegate?.conversationSelected(conversation)
  }
}

protocol ConversationTableViewDelegate {
  func conversationSelected(conversation: Conversation)
}
