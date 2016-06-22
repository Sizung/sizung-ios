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
  @IBOutlet weak var assigneeImageView: UIImageView!
  
  var deliverable: Deliverable!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let conversation = StorageManager.sharedInstance.getConversation(deliverable.conversation.id) {
      titleButton.setTitle("@\(conversation.title)", forState: .Normal)
    }
    backButton.setTitle("< \(deliverable.title)", forState: .Normal)
    
    if let user = StorageManager.sharedInstance.getUser((deliverable.assignee.id)!) {
      let gravatar = Gravatar(emailAddress: user.email, defaultImage: .Identicon)
      
      let size = assigneeImageView.frame.size
      
      assigneeImageView.af_setImageWithURL(
        gravatar.URL(size: size.height),
        placeholderImage: nil,
        filter: AspectScaledToFillSizeWithRoundedCornersFilter(size: size, radius: 20.0),
        imageTransition: .CrossDissolve(0.2)
      )
    }
    
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
      timelineTableViewController.conversation = deliverable?.conversation
      timelineTableViewController.timelineParent = deliverable
    }
  }
}
