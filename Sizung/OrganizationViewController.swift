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
  @IBOutlet weak var segmentedControl: UISegmentedControl!
  
  var mainPageViewController: MainPageViewController!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let storageManager = StorageManager.sharedInstance
    storageManager.isLoading.observeNext { isLoading in
      if let selectedOrganizationId = KeychainWrapper.stringForKey(Configuration.Settings.SELECTED_ORGANIZATION) {
        if let selectedOrganization = storageManager.getOrganization(selectedOrganizationId) {
          self.titleBarButtonItem.title = selectedOrganization.attributes.name
        }
      }
      }.disposeIn(rBag)
    
    segmentedControl.addTarget(self, action: #selector(self.segmentedControlDidChange), forControlEvents: .ValueChanged);
  }
  
  func segmentedControlDidChange(sender: UISegmentedControl){
    
    let selectedIndex = sender.selectedSegmentIndex
    
    self.mainPageViewController.setSelectedIndex(selectedIndex)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "embed" {
      self.mainPageViewController = segue.destinationViewController as! MainPageViewController
      self.mainPageViewController.mainPageViewControllerDelegate = self
    }
  }
  
  func mainpageViewController(mainPageViewController: MainPageViewController, didSwitchToIndex index: Int) {
    segmentedControl.selectedSegmentIndex = index
  }
}
