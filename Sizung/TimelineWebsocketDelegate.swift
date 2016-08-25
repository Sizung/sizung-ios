//
//  TimelineWebsocketDelegate.swift
//  Sizung
//
//  Created by Markus Klepp on 05/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation

extension TimelineTableViewController: WebsocketDelegate {
  func onConnectFailed() {
    InAppMessage.showErrorMessage("There has been an error connecting to this Timeline")
  }

  func onDisconnected() {
    InAppMessage.showErrorMessage("You have been disconnected from this Timeline")
  }

  func onFollowSuccess(itemId: String) {
    InAppMessage.showSuccessMessage("Reconnected to sizung")
  }

  func onReceived(conversationObject: BaseModel) {
    addItemToCollection(conversationObject)
  }
}
