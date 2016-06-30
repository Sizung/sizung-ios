//
//  DeliverableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 14/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import AlamofireImage

class DeliverableViewController: UIViewController {
  
  @IBOutlet weak var titleButton: UIButton!
  @IBOutlet weak var statusButton: UIButton!
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var assigneeImageView: AvatarImageView!
  
  var deliverable: Deliverable!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        
        
        switch self.deliverable {
        case let agendaItemDeliverable as AgendaItemDeliverable:
          
          storageManager.getAgendaItem(agendaItemDeliverable.agendaItemId)
            .onSuccess { agendaItem in
              storageManager.getConversation(agendaItem.conversationId)
                .onSuccess { conversation in
                  self.titleButton.setTitle("@\(conversation.title)", forState: .Normal)
              }
          }
        default:
          storageManager.getConversation(self.deliverable.parentId)
            .onSuccess { conversation in
              self.titleButton.setTitle("@\(conversation.title)", forState: .Normal)
          }
        }
        
        storageManager.getUser(self.deliverable.assigneeId)
          .onSuccess { user in
            self.assigneeImageView.user = user
        }
    }
    
    backButton.setTitle("< \(deliverable.title)", forState: .Normal)
    
    var statusString = deliverable.status
    
    if let dueDate = deliverable.due_on {
      statusString = DueDateHelper.getDueDateString(dueDate)
    }
    
    statusButton.setTitle(statusString, forState: .Normal)
  }
  
  @IBAction func close(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    
    if let timelineTableViewController = segue.destinationViewController as? TimelineTableViewController {
      timelineTableViewController.timelineParent = deliverable
    }
  }
}
