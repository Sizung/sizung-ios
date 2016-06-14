//
//  Websocket.swift
//  Sizung
//
//  Created by Markus Klepp on 10/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import ActionCableClient
import ObjectMapper

class Websocket {
  
  static let CHANNEL_CONVERSATION = "ConversationChannel"
  static let CHANNEL_ORGANIZATION = "OrganizationChannel"
  static let CHANNEL_USER = "UserChannel"
  
  var client : ActionCableClient
  
  var connectedChannels: [String: Channel] = [:]
  
  var conversationWebsocketDelegate: ConversationWebsocketDelegate?
  
  init(authToken: String){
    client = ActionCableClient(URL: NSURL(string: Configuration.websocketEndpoint())!)
    
    client.headers = ["Authorization": "Bearer \(authToken)"]
    client.origin = Configuration.websocketOrigin()
    
    client.onConnected = {
      print("Connected!")
    }
    
    client.onDisconnected = {(error: ErrorType?) in
      print("Disconnected! \(error)")
    }
    
    client.onRejected = {
      print("websocket connection rejected!")
    }
    
    client.connect()
  }
  
  func connectToConversation(id: String){
    
    guard client.connected else {
      print("client not connected")
      return
    }
    
    guard connectedChannels[id] == nil else {
      print("already connected to channel")
      return
    }
    
    let channel = client.create(Websocket.CHANNEL_CONVERSATION, identifier: nil, autoSubscribe: true)
    
    channel.onReceive = { (JSON : AnyObject?, error : ErrorType?) in
      if let websocketResponse = Mapper<WebsocketResponse>().map(JSON) {
        switch websocketResponse.payload {
        case let comment as Comment:
          self.conversationWebsocketDelegate?.onReceived(comment)
        default:
          print("Received", JSON, error)
        }
      }
    }
    
    // A channel has successfully been subscribed to.
    channel.onSubscribed = {
      print("Yay!")
      guard channel.action("follow", params: ["conversation_id": id]) == nil else {
        print("error connecting")
        return
      }
    }
    
    // A channel was unsubscribed, either manually or from a client disconnect.
    channel.onUnsubscribed = {
      print("Unsubscribed")
      self.connectedChannels.removeValueForKey(id)
    }
    
    // The attempt at subscribing to a channel was rejected by the server.
    channel.onRejected = {
      print("Rejected")
      self.connectedChannels.removeValueForKey(id)
    }
    
    channel.subscribe()
    
    connectedChannels[id] = channel
  }
  
  func disconnectFromConversation(id: String){
    guard client.connected else {
      print("client not connected")
      return
    }
    
    if let channel = self.connectedChannels[id] {
      guard channel.action("unfollow", params: ["conversation_id": id]) == nil else {
        print("error disconnecting")
        return
      }
    }else {
      print("channel not connected")
    }
  }
}

protocol ConversationWebsocketDelegate {
  func onReceived(comment: Comment)
}