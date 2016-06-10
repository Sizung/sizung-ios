//
//  ConversationViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 02/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class ConversationViewController: UIViewController, MainPageViewControllerDelegate {
  
  @IBOutlet weak var titleBarButtonItem: UIBarButtonItem!
  @IBOutlet weak var segmentedControl: SizungSegmentedControl!
  
  var mainPageViewController: MainPageViewController!
  
  var conversation: Conversation!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.titleBarButtonItem.title = conversation.title
    
    segmentedControl.items = ["TO DISCUSS", "CHAT", "TO DO"]
    segmentedControl.thumbColors = [Color.TODISCUSS, Color.CHAT, Color.TODO]
    segmentedControl.addTarget(self, action: #selector(self.segmentedControlDidChange), forControlEvents: .ValueChanged);
  }
  
  func segmentedControlDidChange(sender: SizungSegmentedControl){
    
    let selectedIndex = sender.selectedIndex
    
    self.mainPageViewController.setSelectedIndex(selectedIndex)
  }
  
  @IBAction func close(sender: AnyObject) {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "embed" {
      self.mainPageViewController = segue.destinationViewController as! MainPageViewController
      self.mainPageViewController.mainPageViewControllerDelegate = self
      /*
       let label = UILabel()
       label.text = "tba"
       let emptyViewController = UIViewController()
       emptyViewController.view = label
       
       
       self.mainPageViewController.orderedViewControllers.append(emptyViewController)
       self.mainPageViewController.orderedViewControllers.append(emptyViewController)
       self.mainPageViewController.orderedViewControllers.append(emptyViewController)
       */
      let agendaItemsTableViewController = UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewControllerWithIdentifier("AgendaItemsTableViewController") as! AgendaItemsTableViewController
      agendaItemsTableViewController.conversation = self.conversation
      
      self.mainPageViewController.orderedViewControllers.append(agendaItemsTableViewController)
      
      let timelineTableViewController = UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewControllerWithIdentifier("TimelineTableViewController") as! TimelineTableViewController
      timelineTableViewController.conversation = self.conversation
      self.mainPageViewController.orderedViewControllers.append(timelineTableViewController)
      
      let deliverablesTableViewController = UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewControllerWithIdentifier("ConversationDeliverablesTableViewController") as! ConversationDeliverablesTableViewController
      deliverablesTableViewController.conversation = conversation
      self.mainPageViewController.orderedViewControllers.append(deliverablesTableViewController)
    } else {
      fatalError("unkown segue")
    }
  }
  
  func mainpageViewController(mainPageViewController: MainPageViewController, didSwitchToIndex index: Int) {
    segmentedControl.selectedIndex = index
  }
}