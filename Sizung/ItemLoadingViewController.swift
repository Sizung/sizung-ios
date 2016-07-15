//
//  ItemLoadingViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 14/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class ItemLoadingViewController: UIViewController {

  var type: String = "unkown"
  var itemId: String = "unkown"

  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var retryButton: UIButton!

  var itemloadDelegate: ItemLoadDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    loadItem()
  }

  @IBAction func retry(sender: AnyObject) {
    loadItem()
  }

  @IBAction func close(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }

  func loadItem() {

    // after 5s show reload and close button
    Helper.delay(5) {
      UIView.animateWithDuration(0.3) {
        self.closeButton.alpha = 1
        self.retryButton.alpha = 1
      }
    }

    // simplify organization loading
    switch type {
    case "agenda_items":
      StorageManager.sharedInstance.getAgendaItem(itemId)
        .onSuccess { agendaItem in

          StorageManager.sharedInstance.getConversation(agendaItem.conversationId)
            .onSuccess { conversation in
              // set selected organization according to entity
              Configuration.setSelectedOrganization(conversation.organizationId)

              self.openViewControllerFor(agendaItem, inConversation: conversation)
          }
      }
      break
    case "deliverables":
      StorageManager.sharedInstance.getDeliverable(itemId)
        .onSuccess { deliverable in

          switch deliverable {
          case let agendaItemDeliverable as AgendaItemDeliverable:
            StorageManager.sharedInstance.getAgendaItem(agendaItemDeliverable.agendaItemId)
              .onSuccess { agendaItem in
                StorageManager.sharedInstance.getConversation(agendaItem.conversationId)
                  .onSuccess { conversation in
                    self.openViewControllerFor(deliverable, inConversation: conversation)
                }
            }
          default:
            StorageManager.sharedInstance.getConversation(deliverable.parentId)
              .onSuccess { conversation in
                self.openViewControllerFor(deliverable, inConversation: conversation)
            }
          }
      }
      break
    case "conversations":
      StorageManager.sharedInstance.getConversation(itemId)
        .onSuccess { conversation in

          self.openViewControllerFor(nil, inConversation: conversation)

      }
      break
    case "organizations":
      self.itemloadDelegate?.onItemLoaded(itemId, viewController: nil)
    case "attachments":
      // not yet implemented
      break
    default:
      let message = "link to unknown type \(type) with id:\(itemId)"
      Error.log(message)
    }
  }

  func openViewControllerFor(item: BaseModel?, inConversation conversation: Conversation) {
    let conversationController = R.storyboard.conversation.initialViewController()!
    conversationController.conversation = conversation
    conversationController.openItem = item

    itemloadDelegate?.onItemLoaded(conversation.organizationId, viewController: conversationController)
  }
}

protocol ItemLoadDelegate {
  func onItemLoaded(organizationId: String, viewController: UIViewController?)
}
