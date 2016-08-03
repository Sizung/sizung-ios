//
//  AppLoginDelegate.swift
//  Sizung
//
//  Created by Markus Klepp on 03/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation

extension AppDelegate: LoginDelegate {

  func loginSuccess(loginViewController: LoginViewController) {

    self.loginViewController = nil
    self.registerForPushNotifications()
    self.initWebsocketConnection()

    loginViewController.dismissViewControllerAnimated(true) {
      self.loadInitialViewController()
    }
  }

}
