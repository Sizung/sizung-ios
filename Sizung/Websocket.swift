//
//  Websocket.swift
//  Sizung
//
//  Created by Markus Klepp on 10/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import ActionCableClient

class Websocket {
  
  static let CHANNEL_CONVERSATION = "ConversationChannel"
  static let CHANNEL_ORGANIZATION = "OrganizationChannel"
  static let CHANNEL_USER = "UserChannel"
  
  var client : ActionCableClient
  
  init(headers: Dictionary<String, String>){
    client = ActionCableClient(URL: NSURL(string: Configuration.websocketEndpoint())!)
    
    client.headers = headers
      
    client.onConnected = {
      print("Connected!")
      self.connectToConversation("c164a2e3-1a46-4dde-b34a-617dd1065135")
    }
    
    client.onDisconnected = {(error: ErrorType?) in
      print("Disconnected!")
    }
    
    client.connect()
  }
  
  func connectToConversation(id: String){
    
    guard client.connected else {
      print("client not connected")
      return
    }
    
    let channel = client.create(Websocket.CHANNEL_CONVERSATION, identifier: nil, autoSubscribe: true)
    
    channel.onReceive = { (JSON : AnyObject?, error : ErrorType?) in
      print("Received", JSON, error)
    }
    
    // A channel has successfully been subscribed to.
    channel.onSubscribed = {
      print("Yay!")
    }
    
    // A channel was unsubscribed, either manually or from a client disconnect.
    channel.onUnsubscribed = {
      print("Unsubscribed")
    }
    
    // The attempt at subscribing to a channel was rejected by the server.
    channel.onRejected = {
      print("Rejected")
    }
    
    channel.subscribe()
  }
}
