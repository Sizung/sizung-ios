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

  var client: ActionCableClient

  var conversationChannel: Channel?
  var userChannel: Channel?
  var organizationChannel: Channel?

  // Set containing all channelIDs the socket should follow after socket connect
  var willFollowConversationChannels: Set<String> = []
  var willFollowUserChannels: Set<String> = []

  var conversationWebsocketDelegate: WebsocketDelegate?
  var userWebsocketDelegate: WebsocketDelegate?

  init(authToken: String) {
    client = ActionCableClient(URL: NSURL(string: Configuration.websocketEndpoint())!)

    client.headers = ["Authorization": "Bearer \(authToken)"]
    client.origin = Configuration.websocketOrigin()

    client.onConnected = {
      // connect individual channels
      self.conversationChannel = self.initChannel(.Conversation)
      self.organizationChannel = self.initChannel(.Organization)
      self.userChannel = self.initChannel(.User)
    }

    client.onDisconnected = { error in
      self.conversationWebsocketDelegate?.onDisconnected()
      self.userWebsocketDelegate?.onDisconnected()
    }

    client.onRejected = {
      fatalError("Websocket connection rejected!")
    }

    client.connect()
  }

  func initChannel(type: ChannelType) -> Channel {
    let channel = client.create(type.rawValue, identifier: nil, autoSubscribe: false)

    channel.onReceive = { (JSON: AnyObject?, error: ErrorType?) in
      if let websocketResponse = Mapper<WebsocketResponse>().map(JSON) {
        switch websocketResponse.payload {
        case _ as Comment,
             _ as Deliverable,
             _ as AgendaItem:
          self.conversationWebsocketDelegate?.onReceived(websocketResponse.payload)
        case _ as UnseenObject:
          self.userWebsocketDelegate?.onReceived(websocketResponse.payload)
        default:
          let message = "unkown onReceive: \(JSON) error: \(error)"
          Error.log(message)

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
        break
      }
    }

    // A channel was unsubscribed, either manually or from a client disconnect.
    channel.onUnsubscribed = {

    }

    // The attempt at subscribing to a channel was rejected by the server.
    channel.onRejected = {
      let message = "Rejected subscribe to \(channel.name)"
      Error.log(message)
    }

    channel.subscribe()

    return channel
  }

  func followConversation(conversationId: String) {

    guard client.connected else {
      willFollowConversationChannels.insert(conversationId)
      client.connect()
      return
    }

    guard conversationChannel != nil && conversationChannel!.subscribed else {
      fatalError("conversationchannel not subscribed")
    }

    guard conversationChannel!.action("follow", params: ["conversation_id": conversationId]) == nil else {
      fatalError("error following conversation \(conversationId)")
    }

    self.conversationWebsocketDelegate?.onFollowSuccess(conversationId)
  }

  func unfollowConversation(conversationId: String) {

    willFollowConversationChannels.remove(conversationId)

    guard client.connected else {
      return
    }

    guard conversationChannel != nil && conversationChannel!.subscribed else {
      return
    }

    guard conversationChannel!.action("unfollow", params: ["conversation_id": conversationId]) == nil else {
      fatalError("error disconnecting")
    }
  }

  func followUser(userId: String) {
    guard client.connected else {
      willFollowUserChannels.insert(userId)
      client.connect()
      return
    }

    guard userChannel != nil && userChannel!.subscribed else {
      fatalError("userChannel not subscribed")
    }

    guard userChannel!.action("follow", params: ["user_id": userId]) == nil else {
      fatalError("error following user \(userId)")
    }

    self.userWebsocketDelegate?.onFollowSuccess(userId)
  }
}

protocol WebsocketDelegate {
  func onDisconnected()
  func onFollowSuccess(channelName: String)
  func onReceived(conversationObject: BaseModel)
}
