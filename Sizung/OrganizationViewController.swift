//
//  OrganizationViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 01/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class OrganizationViewController: UIViewController, MainPageViewControllerDelegate {
  
  @IBOutlet weak var titleBarButtonItem: UIBarButtonItem!
  @IBOutlet weak var segmentedControl: SizungSegmentedControl!
  
  var mainPageViewController: MainPageViewController!
  
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
    
    segmentedControl.items = ["To Discuss", "Teams", "To Do"]
    segmentedControl.thumbColors = [Color.TODISCUSS, Color.TEAM, Color.TODO]
    segmentedControl.selectedIndex = 1
    segmentedControl.addTarget(self, action: #selector(self.segmentedControlDidChange), forControlEvents: .ValueChanged);
  }
  
  func segmentedControlDidChange(sender: SizungSegmentedControl){
    
    let selectedIndex = sender.selectedIndex
    
    self.mainPageViewController.setSelectedIndex(selectedIndex)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "embed" {
      self.mainPageViewController = segue.destinationViewController as! MainPageViewController
      self.mainPageViewController.mainPageViewControllerDelegate = self
      
      self.mainPageViewController.orderedViewControllers.append(UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewControllerWithIdentifier("AgendaItemsTableViewController"))
      self.mainPageViewController.orderedViewControllers.append(UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewControllerWithIdentifier("ConversationsTableViewController"))
      
      let deliverablesTableViewController = UIStoryboard(name: "Main", bundle: nil) .
        instantiateViewControllerWithIdentifier("UserDeliverablesTableViewController") as! UserDeliverablesTableViewController
      
      let token = AuthToken(data: KeychainWrapper.stringForKey(Configuration.Settings.AUTH_TOKEN))
      let userId = token.getUserId()
      
      deliverablesTableViewController.userId = userId
       
      self.mainPageViewController.orderedViewControllers.append(deliverablesTableViewController)
    }
    
  }
  
  func mainpageViewController(mainPageViewController: MainPageViewController, didSwitchToIndex index: Int) {
    segmentedControl.selectedIndex = index
  }
}