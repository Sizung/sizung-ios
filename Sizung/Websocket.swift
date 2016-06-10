//
//  Websocket.swift
//  Sizung
//
//  Created by Markus Klepp on 10/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation

class Websocket: NSObject, FayeClientDelegate {
  
  static let CHANNEL_CONVERSATION = "ConversationChannel"
  static let CHANNEL_ORGANIZATION = "OrganizationChannel"
  static let CHANNEL_USER = "UserChannel"
  
  var client : FayeClient?
  
  init(headers: Dictionary<String, String>){
    super.init()
    client = FayeClient(aFayeURLString: Configuration.websocketEndpoint(), headers: headers, channel: Websocket.CHANNEL_CONVERSATION)
    client!.delegate = self
  }
  
  func connect(){
    client!.connectToServer()
  }
  
  func disconnect(){
    client!.disconnectFromServer()
  }
  
  func connectedToServer(client: FayeClient) {
    print("Connected to Faye server")
  }
  
  func connectionFailed(client: FayeClient) {
    print("Failed to connect to Faye server!")
  }
  
  func disconnectedFromServer(client: FayeClient) {
    print("Disconnected from Faye server")
  }
  
  func didSubscribeToChannel(client: FayeClient, channel: String) {
    print("subscribed to channel \(channel)")
  }
  
  func didUnsubscribeFromChannel(client: FayeClient, channel: String) {
    print("Unsubscribed from channel \(channel)")
  }
  
  func subscriptionFailedWithError(client: FayeClient, error: String) {
    print("SUBSCRIPTION FAILED!!!!")
  }
  
  func messageReceived(client: FayeClient, messageDict: NSDictionary, channel: String) {
    let text: AnyObject? = messageDict["text"]
    print("Here is the message: \(text)")
    
    self.client!.unsubscribeFromChannel(channel)
  }
}
