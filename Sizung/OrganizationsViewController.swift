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

  var organizationTableViewDelegate: OrganizationTableViewDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    addOrganizationButton.fabDelegate = self
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

    UIApplication.sharedApplication().statusBarStyle = .LightContent
  }

  @IBAction func showSettings(sender: AnyObject) {
    let accountViewController = R.storyboard.organization.accountViewController()!
    self.showViewController(accountViewController, sender: self)
  }

  func emptyKCFABSelected(fab: KCFloatingActionButton) {
    print("add org")
  }


  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if R.segue.organizationsViewController.embed(segue: segue) != nil {
      if let destinationViewController = segue.destinationViewController as? OrganizationsTableViewController {
        destinationViewController.organizationTableViewDelegate = self.organizationTableViewDelegate
      } else {
        fatalError()
      }
    } else {
      fatalError()
    }
  }
}
