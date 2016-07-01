//
//  DeliverableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 14/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import AlamofireImage

class DeliverableViewController: UIViewController, UIPopoverPresentationControllerDelegate, CalendarViewDelegate {
  
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
  
  @IBAction func showStatusPopover(sender: UIButton) {
    
    if !deliverable.isCompleted() {
      
      let optionMenu = UIAlertController(title: nil, message: "Edit Deliverable", preferredStyle: .ActionSheet)
      
      let dateAction = UIAlertAction(title: "Change due date", style: .Default, handler: { _ in
        self.showDatePicker(sender)
      })
      
      let completeAction = UIAlertAction(title: "Mark as complete", style: .Default, handler: { _ in
        print("complete")
      })
      
      let archiveAction = UIAlertAction(title: "Archive", style: .Default, handler: { _ in
        print("ARCHIVE")
      })
      
      let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
      
      optionMenu.addAction(dateAction)
      optionMenu.addAction(completeAction)
      optionMenu.addAction(archiveAction)
      optionMenu.addAction(cancelAction)
      
      self.presentViewController(optionMenu, animated: true, completion: nil)
    }
  }
  
  func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
    print("dismiss popover")
  }
  
  // show previous view controller
  @IBAction func back(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  func showDatePicker(sender: UIButton) {
    
    let calendarController = R.storyboard.deliverable.calendarController()!
    calendarController.calendarViewDelegate = self
    calendarController.currentDate = deliverable.due_on
    
    calendarController.modalPresentationStyle = .Popover
    self.presentViewController(calendarController, animated: true, completion: nil)
    
    let popoverController = calendarController.popoverPresentationController!
    popoverController.permittedArrowDirections = .Any
    popoverController.sourceView = sender
    popoverController.delegate = self
    
    
  }
  
  func didSelectDate(date: NSDate?) {
    print("delegate \(date)")
  }
  
}
