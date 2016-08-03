//
//  AppItemLoadDelegate.swift
//  Sizung
//
//  Created by Markus Klepp on 03/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

extension AppDelegate: ItemLoadDelegate {

  func onItemLoaded(organizationId: String, viewController: UIViewController?) {

    self.window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
    self.window?.rootViewController = R.storyboard.main.initialViewController()

    if organizationId != Configuration.getSelectedOrganization() {
      // reset storage
      StorageManager.sharedInstance.reset()
      Configuration.setSelectedOrganization(organizationId)
    }

    let organizationViewController = R.storyboard.organization.initialViewController()!
    organizationViewController.conversationViewController = viewController
    self.window?.rootViewController?.showViewController(organizationViewController, sender: nil)
  }
}
