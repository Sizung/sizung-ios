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
    let storageManager = StorageManager.sharedInstance
    storageManager.isLoading.observeNext { isLoading in
      if let selectedOrganizationId = KeychainWrapper.stringForKey(Configuration.Settings.SELECTED_ORGANIZATION) {
        if let selectedOrganization = storageManager.getOrganization(selectedOrganizationId) {
          self.titleBarButtonItem.title = selectedOrganization.name
        }
      }
      }.disposeIn(rBag)
    
    segmentedControl.items = ["To Discuss", "Chat", "To Do"]
    segmentedControl.thumbColors = [Color.TODISCUSS, Color.CHAT, Color.TODO]
    segmentedControl.selectedIndex = 1
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
      self.mainPageViewController.loadViewControllersNamed("AgendaItemsTableViewController",
                                                      "TimelineTableViewController",
                                                      "ConversationDeliverablesTableViewController")
    }
  }
  
  func mainpageViewController(mainPageViewController: MainPageViewController, didSwitchToIndex index: Int) {
    segmentedControl.selectedIndex = index
  }
}