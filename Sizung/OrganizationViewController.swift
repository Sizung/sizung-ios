//
//  OrganizationViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 01/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import Sheriff

class OrganizationViewController: UIViewController, MainPageViewControllerDelegate {
  
  
  @IBOutlet weak var segmentedControl: SizungSegmentedControl!
  
  @IBOutlet weak var titleButton: UIButton!
  @IBOutlet weak var groupsButton: UIButton!
  
  var groupsBadgeView = GIBadgeView()
  
  var mainPageViewController: MainPageViewController!
  
  var organizationsViewController: UIViewController?
  var groupsViewController: UIViewController?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.groupsButton.addSubview(groupsBadgeView)
    
    let storageManager = StorageManager.sharedInstance
    storageManager.organizations.observeNext { _ in
      self.setTitle()
      }.disposeIn(rBag)
    
    storageManager.conversations.observeNext { _ in
      self.groupsBadgeView.badgeValue = storageManager.conversations.count
    }.disposeIn(rBag)
    
    segmentedControl.items = ["PRIORITY", "DISCUSS", "ACTION"]
    segmentedControl.thumbColors = [Color.TODISCUSS, Color.STREAM, Color.TODO]
    segmentedControl.addTarget(self, action: #selector(self.segmentedControlDidChange), forControlEvents: .ValueChanged);
  }
  
  func setTitle(){
    if let selectedOrganizationId = KeychainWrapper.stringForKey(Configuration.Settings.SELECTED_ORGANIZATION) {
      if let selectedOrganization = StorageManager.sharedInstance.getOrganization(selectedOrganizationId) {
        UIView.animateWithDuration(1, animations: {
          self.titleButton.alpha = 1
        })
        self.titleButton.setTitle(selectedOrganization.name, forState: .Normal)
      }
    }
  }
  
  func segmentedControlDidChange(sender: SizungSegmentedControl){
    
    let selectedIndex = sender.selectedIndex
    
    self.mainPageViewController.setSelectedIndex(selectedIndex)
  }
  
  @IBAction func showOrganizations(sender: AnyObject) {
    organizationsViewController = R.storyboard.organizations.initialViewController()
    self.showViewController(organizationsViewController!, sender: self)
  }
  
  @IBAction func hideOrganizations(sender: AnyObject) {
    organizationsViewController?.dismissViewControllerAnimated(true, completion: nil)
    organizationsViewController = nil
  }
  
  @IBAction func showGroups(sender: AnyObject) {
    groupsViewController = R.storyboard.conversations.initialViewController()
    self.showViewController(groupsViewController!, sender: self)
  }
  
  @IBAction func hideGroups(sender: AnyObject) {
    groupsViewController?.dismissViewControllerAnimated(true, completion: nil)
    groupsViewController = nil
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "embed" {
      self.mainPageViewController = segue.destinationViewController as! MainPageViewController
      self.mainPageViewController.mainPageViewControllerDelegate = self
      
      self.mainPageViewController.orderedViewControllers.append(R.storyboard.main.agendaItemsTableViewController()!)
      self.mainPageViewController.orderedViewControllers.append(R.storyboard.main.streamTableViewController()!)
      
      let deliverablesTableViewController = R.storyboard.main.userDeliverablesTableViewController()!
      
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