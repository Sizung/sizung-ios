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
  
  enum ChannelType: String {
    case Organization = "OrganizationChannel"
    case Conversation = "ConversationChannel"
    case User = "UserChannel"
  }
  
  var client : ActionCableClient
  
  var conversationChannel: Channel?
  var userChannel: Channel?
  var organizationChannel: Channel?
  
  // Set containing all channelIDs the socket should follow after socket connect
  var willFollowConversationChannels: Set<String> = []
  var willFollowUserChannels: Set<String> = []
  
  var conversationWebsocketDelegate: WebsocketDelegate?
  var userWebsocketDelegate: WebsocketDelegate?
  
  init(authToken: String){
    client = ActionCableClient(URL: NSURL(string: Configuration.websocketEndpoint())!)
    
    client.headers = ["Authorization": "Bearer \(authToken)"]
    client.origin = Configuration.websocketOrigin()
    
    client.onConnected = {
      // connect individual channels
      self.conversationChannel = self.initChannel(.Conversation)
      self.organizationChannel = self.initChannel(.Organization)
      self.userChannel = self.initChannel(.User)
    }
    
    client.onDisconnected = {(error: ErrorType?) in
      print("Websocket disconnected! \(error)")
    }
    
    client.onRejected = {
      fatalError("Websocket connection rejected!")
    }
    
    client.connect()
  }
  
  func initChannel(type: ChannelType) -> Channel{
    let channel = client.create(type.rawValue, identifier: nil, autoSubscribe: false)
    
    channel.onReceive = { (JSON : AnyObject?, error : ErrorType?) in
      if let websocketResponse = Mapper<WebsocketResponse>().map(JSON) {
        switch websocketResponse.payload {
        case _ as Comment,
             _ as Deliverable,
             _ as AgendaItem:
          self.conversationWebsocketDelegate?.onReceived(websocketResponse.payload)
        case _ as UnseenObject:
          self.userWebsocketDelegate?.onReceived(websocketResponse.payload)
        default:
          print("Received", JSON, error)
        }
      }
    }
    
    // A channel has successfully been subscribed to.
    channel.onSubscribed = {
      switch channel.name {
      case ChannelType.Organization.rawValue:
        for channelId in self.willFollowConversationChannels {
          self.followConversation(channelId)
        }
      case ChannelType.User.rawValue:
        for channelId in self.willFollowUserChannels {
          self.followUser(channelId)
        }
      default:
        print("Subscribed to \(channel.name)")
      }
    }
    
    // A channel was unsubscribed, either manually or from a client disconnect.
    channel.onUnsubscribed = {
      print("Unsubscribed from \(channel.name)")
    }
    
    // The attempt at subscribing to a channel was rejected by the server.
    channel.onRejected = {
      print("Rejected subscribe to \(channel.name)")
    }
    
    channel.subscribe()
    
    return channel
  }
  
  func followConversation(id: String){
    
    guard client.connected else {
      willFollowConversationChannels.insert(id)
      client.connect()
      return
    }
    
    guard conversationChannel != nil && conversationChannel!.subscribed else {
      fatalError("conversationchannel not subscribed")
    }
    
    guard conversationChannel!.action("follow", params: ["conversation_id": id]) == nil else {
      fatalError("error following conversation \(id)")
    }
    
    self.conversationWebsocketDelegate?.onFollowSuccess(id)
  }
  
  func unfollowConversation(id: String){
    
    willFollowConversationChannels.remove(id)
    
    guard client.connected else {
      print("Websocket client not connected")
      return
    }
    
    guard conversationChannel != nil && conversationChannel!.subscribed else {
      print("Conversationchannel not subscribed")
      return
    }
    
    guard conversationChannel!.action("unfollow", params: ["conversation_id": id]) == nil else {
      fatalError("error disconnecting")
    }
    
    print("Unfollowing conversation \(id)")
  }
  
  func followUser(id: String){
    guard client.connected else {
      willFollowUserChannels.insert(id)
      client.connect()
      return
    }
    
    guard userChannel != nil && userChannel!.subscribed else {
      fatalError("userChannel not subscribed")
    }
    
    guard userChannel!.action("follow", params: ["user_id": id]) == nil else {
      fatalError("error following user \(id)")
    }
    
    self.userWebsocketDelegate?.onFollowSuccess(id)
  }
}

protocol WebsocketDelegate {
  func onFollowSuccess(channelName: String)
  func onReceived(conversationObject: BaseModel)
}