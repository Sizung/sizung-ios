//
//  OrganizationsViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 16/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import KCFloatingActionButton

class OrganizationsViewController: UIViewController, KCFloatingActionButtonDelegate {
  
  @IBOutlet weak var addOrganizationButton: KCFloatingActionButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    addOrganizationButton.fabDelegate = self
  }
  
  @IBAction func showSettings(sender: AnyObject) {
    let accountViewController = R.storyboard.main.accountViewController()!
    self.showViewController(accountViewController, sender: self)
  }
  
  func emptyKCFABSelected(fab: KCFloatingActionButton) {
    print("add org")
  }
}
