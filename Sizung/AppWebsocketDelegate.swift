//
//  AppWebsocketDelegate.swift
//  Sizung
//
//  Created by Markus Klepp on 03/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation

extension AppDelegate: WebsocketDelegate {
  func onConnectFailed() {
    InAppMessage.showErrorMessage("There has been an error connecting to Sizung")
  }

  func onDisconnected() {
    InAppMessage.showErrorMessage("You have been disconnected from Sizung")
  }

  func onReceived(unseenObject: BaseModel) {

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        if let unseenObject = unseenObject as? UnseenObject {
          if unseenObject.timeline != nil && unseenObject.target != nil {
            storageManager.unseenObjects.insertOrUpdate([unseenObject])
          } else {
            // remove if no timeline or target
            if let index = storageManager.unseenObjects.indexOf(unseenObject) {
              storageManager.unseenObjects.removeAtIndex(index)
            }
          }
        }
    }
  }

  func onFollowSuccess(channelName: String) {
  }
}
