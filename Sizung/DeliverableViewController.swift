//
//  DeliverableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 14/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class DeliverableViewController: UIViewController {
  
  @IBOutlet weak var titleBarButtonItem: UIBarButtonItem!
  @IBOutlet weak var statusButton: UIButton!
  @IBOutlet weak var backButton: UIButton!
  
  var deliverable: Deliverable?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    titleBarButtonItem.title = deliverable?.title
    if let conversation = StorageManager.sharedInstance.getConversation(deliverable!.conversation.id) {
      backButton.setTitle(conversation.title, forState: .Normal)
    }
    statusButton.setTitle(deliverable?.status, forState: .Normal)
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
