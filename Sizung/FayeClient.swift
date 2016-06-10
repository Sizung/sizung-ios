//
//  FayeClient.swift
//  FayeSwift
//
//  Created by Haris Amin on 8/31/14.
//  Copyright (c) 2014 Haris Amin. All rights reserved.
//

import Foundation
import Starscream
import SwiftyJSON

// MARK: Custom Extensions
extension String {
  subscript (i: Int) -> String {
    return String(Array(self.characters)[i])
  }
}


// MARK: BayuexChannel Messages
enum BayeuxChannel : CustomStringConvertible {
  case HANDSHAKE_CHANNEL;
  case CONNECT_CHANNEL;
  case DISCONNECT_CHANNEL;
  case SUBSCRIBE_CHANNEL;
  case UNSUBSCRIBE_CHANNEL;
  
  var description : String {
    switch self {
    // Use Internationalization, as appropriate.
    case .HANDSHAKE_CHANNEL: return "/meta/handshake";
    case .CONNECT_CHANNEL: return "/meta/connect";
    case .DISCONNECT_CHANNEL: return "/meta/disconnect";
    case .SUBSCRIBE_CHANNEL: return "/meta/subscribe";
    case .UNSUBSCRIBE_CHANNEL: return "/meta/unsubscribe";
    }
  }
}


// MARK: Type Aliases
typealias ChannelSubscriptionBlock = (NSDictionary) -> Void

// MARK: FayeClientDelegate Protocol
protocol FayeClientDelegate: NSObjectProtocol{
  func messageReceived(messageDict: NSDictionary, channel: String)
  func connectedToServer()
  func disconnectedFromServer()
  func connectionFailed()
  func didSubscribeToChannel(channel:String)
  func didUnsubscribeFromChannel(channel:String)
  func subscriptionFailedWithError(error:String)
  func fayeClientError(error:NSError)
}

extension FayeClientDelegate {
  func messageReceived(messageDict: NSDictionary, channel: String){}
  func connectedToServer(){}
  func disconnectedFromServer(){}
  func connectionFailed(){}
  func didSubscribeToChannel(channel:String){}
  func didUnsubscribeFromChannel(channel:String){}
  func subscriptionFailedWithError(error:String){}
  func fayeClientError(error:NSError){}
}


protocol Transport{
  func writeString(aString:String)
  func openConnection(headers: [String:String]?)
  func closeConnection()
  func isConnected() -> (Bool)
}

public protocol TransportDelegate: class{
  func didConnect()
  func didFailConnection(error:NSError?)
  func didDisconnect()
  func didWriteError(error:NSError?)
  func didReceiveMessage(text:String)
}

public class WebsocketTransport: Transport, WebSocketDelegate {
  var urlString:String?
  var webSocket:WebSocket?
  public weak var delegate:TransportDelegate?
  
  convenience required public init(url: String) {
    self.init()
    self.urlString = url
  }
  
  func openConnection(headers: Dictionary<String, String>?){
    self.closeConnection()
    self.webSocket = WebSocket(url: NSURL(string:self.urlString!)!)
    self.webSocket!.delegate = self;
    for (headerName, headerValue) in headers  ?? Dictionary<String,String>() {
      self.webSocket?.headers[headerName] = headerValue
    }
    self.webSocket!.connect()
  }
  
  func closeConnection(){
    if(self.webSocket != nil){
      self.webSocket!.delegate = nil
      self.webSocket!.disconnect()
      self.webSocket = nil;
    }
  }
  
  func writeString(aString:String){
    self.webSocket?.writeString(aString)
  }
  
  func isConnected() -> (Bool){
    return self.webSocket!.isConnected
  }
  
  // MARK: Websocket Delegate
  public func websocketDidConnect(socket: WebSocket) {
    print("websocket is connected")
    self.delegate?.didConnect()
  }
  
  public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
    
    if(error == nil){
      print("websocket lost connection!")
      self.delegate?.didDisconnect()
    }else{
      print("websocket is disconnected: \(error!.localizedDescription)")
      self.delegate?.didFailConnection(error)
    }
  }
  
  public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
    print("got some text: \(text)")
    self.delegate?.didReceiveMessage(text)
  }
  
  // MARK: TODO
  public func websocketDidReceiveData(socket: WebSocket, data: NSData) {
    print("got some data: \(data.length)")
    //self.socket.writeData(data)
  }
}

// MARK: FayeClient
class FayeClient : TransportDelegate {
  var fayeURLString:String
  var fayeClientId:String?
  weak var delegate:FayeClientDelegate?
  var transport:WebsocketTransport?
  
  private var fayeConnected:Bool?
  private var connectionExtension: [String: String] = [:]
  private var headers: [String: String]?
  private var connectionInitiated:Bool?
  private var messageNumber:UInt32 = 0
  
  private var queuedSubscriptions = NSMutableSet()
  private var pendingSubscriptions = NSMutableSet()
  private var openSubscriptions = NSMutableSet()
  
  private var channelSubscriptionBlocks = Dictionary<String,ChannelSubscriptionBlock>()
  
  init(aFayeURLString:String, headers: Dictionary<String, String>?, channel:String?) {
    self.fayeURLString = aFayeURLString
    self.fayeConnected = false;
    
    self.headers = headers
    
    self.transport = WebsocketTransport(url: aFayeURLString)
    self.transport!.delegate = self;
    
    if(channel != nil){
      self.queuedSubscriptions.addObject(channel!)
    }
    self.connectionInitiated = false
  }
  
  convenience init(aFayeURLString:String, channel:String, channelBlock:ChannelSubscriptionBlock){
    self.init(aFayeURLString: aFayeURLString, headers: nil, channel: channel)
    self.channelSubscriptionBlocks[channel] = channelBlock;
  }
  
  func addExtension(key: String, value: String){
    self.connectionExtension[key] = value
  }
  
  func connectToServer(){
    if(self.connectionInitiated != true){
      self.transport?.openConnection(self.headers)
      self.connectionInitiated = true;
    }
  }
  
  func disconnectFromServer(){
    self.disconnect()
  }
  
  func sendMessage(messageDict: NSDictionary, channel:String){
    
    self.publish(messageDict as! Dictionary, channel: channel)
  }
  
  func sendMessage(messageDict:[String:AnyObject], channel:String){
    self.publish(messageDict, channel: channel)
  }
  
  func subscribeToChannel(channel:String){
    if(self.isSubscribedToChannel(channel) || self.pendingSubscriptions.containsObject(channel) ){
      return
    }
    
    if(self.fayeConnected == true){
      self.subscribe(channel)
    }else{
      self.queuedSubscriptions.addObject(channel)
    }
  }
  
  func subscribeToChannel(channel:String, block:ChannelSubscriptionBlock){
    self.subscribeToChannel(channel)
    self.channelSubscriptionBlocks[channel] = block;
  }
  
  func unsubscribeFromChannel(channel:String){
    self.queuedSubscriptions.removeObject(channel)
    self.unsubscribe(channel)
    self.channelSubscriptionBlocks[channel] = nil;
    self.openSubscriptions.removeObject(channel)
    self.pendingSubscriptions.removeObject(channel)
  }
  
  func isSubscribedToChannel(channel:String) -> (Bool){
    return self.openSubscriptions.containsObject(channel)
  }
  
  func isTransportConnected() -> (Bool){
    return self.transport!.isConnected()
  }
}


// MARK: Transport Delegate
extension FayeClient {
  func didConnect() {
    print("Transport websocket is connected")
    self.connectionInitiated = false;
    self.handshake()
  }
  
  func didDisconnect() {
    print("Transport websocket lost connection!")
    self.delegate?.disconnectedFromServer()
    self.connectionInitiated = false
    self.fayeConnected = false
  }
  
  func didFailConnection(error: NSError?) {
    print("Transport websocket is disconnected: \(error!.localizedDescription)")
    self.delegate?.connectionFailed()
    self.connectionInitiated = false
    self.fayeConnected = false
  }
  
  func didWriteError(error: NSError?) {
    if(error == nil){
      print("Transport websocket write failed: ERROR IS NIL!")
    }else{
      print("Transport websocket write failed: \(error!.localizedDescription)")
      self.delegate?.fayeClientError(error!)
    }
  }
  
  func didReceiveMessage(text: String) {
    print("Transport got some text: \(text)")
    self.receive(text)
  }
  
}

// MARK: Private Bayuex Methods
private extension FayeClient {
  func parseFayeMessage(messageJSON:JSON){
    
    let messageDict = messageJSON[0]
    if let channel = messageDict["channel"].string{
      
      switch(channel)
      {
      case BayeuxChannel.HANDSHAKE_CHANNEL.description:
        print("HANDSHAKE_CHANNEL")
        self.fayeClientId = messageDict["clientId"].stringValue
        if(messageDict["successful"].int == 1){
          
          self.delegate?.connectedToServer()
          self.fayeConnected = true;
          self.connect()
          self.subscribeQueuedSubscriptions()
          
        }else{
          // OOPS
        }
        
      case BayeuxChannel.CONNECT_CHANNEL.description:
        print("CONNECT_CHANNEL")
        if(messageDict["successful"].int == 1){
          self.fayeConnected = true;
          self.connect()
        }else{
          // OOPS
        }
      case BayeuxChannel.DISCONNECT_CHANNEL.description:
        print("DISCONNECT_CHANNEL")
        if(messageDict["successful"].int == 1){
          self.fayeConnected = false;
          self.transport?.closeConnection()
          self.delegate?.disconnectedFromServer()
        }else{
          // OOPS
        }
      case BayeuxChannel.SUBSCRIBE_CHANNEL.description:
        print("SUBSCRIBE_CHANNEL")
        
        let success = messageJSON[0]["successful"].int
        
        if( success == 1){
          if let subscription = messageJSON[0]["subscription"].string{
            self.pendingSubscriptions.removeObject(subscription)
            self.openSubscriptions.addObject(subscription)
            self.delegate?.didSubscribeToChannel(subscription)
          }else{
            print("Missing subscription for Subscribe")
          }
        }else{
          // Subscribe Failed
          if let error = messageJSON[0]["error"].string{
            self.delegate?.subscriptionFailedWithError(error)
          }
        }
      case BayeuxChannel.UNSUBSCRIBE_CHANNEL.description:
        print("UNSUBSCRIBE_CHANNEL")
        
        if let subscription = messageJSON[0]["subscription"].string{
          self.openSubscriptions.removeObject(subscription)
          self.delegate?.didUnsubscribeFromChannel(subscription)
        }else{
          print("Missing subscription for Unsubscribe")
        }
      default:
        if(self.isSubscribedToChannel(channel)){
          print("New Message on \(channel)")
          
          if(messageJSON[0]["data"] != JSON.null){
            // Call channel subscription block if there is one
            let data: AnyObject = messageJSON[0]["data"].object
            if let channelBlock = self.channelSubscriptionBlocks[channel]{
              channelBlock(data as! NSDictionary)
            }else{
              self.delegate?.messageReceived(data as! NSDictionary, channel: channel)
            }
            
          }else{
            print("For some reason data is nil, maybe double posting?!")
          }
          
        }else{
          print("weird channel")
        }
      }
      
    }else{
      print("Missing channel")
    }
  }
  
  /**
   Bayeux messages
   */
  
  // Bayeux Handshake
  // "channel": "/meta/handshake",
  // "version": "1.0",
  // "minimumVersion": "1.0beta",
  // "supportedConnectionTypes": ["long-polling", "callback-polling", "iframe", "websocket]
  func handshake() {
    let connTypes:NSArray = ["long-polling", "callback-polling", "iframe", "websocket"]
    var dict = [String: AnyObject]()
    dict["channel"] = BayeuxChannel.HANDSHAKE_CHANNEL.description
    dict["version"] = "1.0"
    dict["minimumVersion"] = "1.0beta"
    dict["supportedConnectionTypes"] = connTypes
    dict["ext"] = connectionExtension
    
    let string = JSONStringify(dict)
    self.transport?.writeString(string)
  }
  
  // Bayeux Connect
  // "channel": "/meta/connect",
  // "clientId": "Un1q31d3nt1f13r",
  // "connectionType": "long-polling"
  func connect(){
    let dict:[String:AnyObject] = ["channel": BayeuxChannel.CONNECT_CHANNEL.description, "clientId": self.fayeClientId!, "connectionType": "websocket", "ext": connectionExtension]
    
    let string = JSONStringify(dict)
    self.transport?.writeString(string)
  }
  
  // Bayeux Disconnect
  // "channel": "/meta/disconnect",
  // "clientId": "Un1q31d3nt1f13r"
  func disconnect(){
    let dict:[String:AnyObject] = ["channel": BayeuxChannel.DISCONNECT_CHANNEL.description, "clientId": self.fayeClientId!, "connectionType": "websocket", "ext": connectionExtension]
    let string = JSONStringify(dict)
    self.transport?.writeString(string)
  }
  
  // Bayeux Subscribe
  // {
  // "channel": "/meta/subscribe",
  // "clientId": "Un1q31d3nt1f13r",
  // "subscription": "/foo/**"
  // }
  func subscribe(channel:String){
    let dict:[String:AnyObject] = ["channel": BayeuxChannel.SUBSCRIBE_CHANNEL.description, "clientId": self.fayeClientId!, "subscription": channel, "ext": connectionExtension]
    let string = JSONStringify(dict)
    self.transport?.writeString(string)
    self.pendingSubscriptions.addObject(channel)
  }
  
  // Bayeux Unsubscribe
  // {
  // "channel": "/meta/unsubscribe",
  // "clientId": "Un1q31d3nt1f13r",
  // "subscription": "/foo/**"
  // }
  func unsubscribe(channel:String){
    if let clientId = self.fayeClientId {
      let dict:[String:AnyObject] = ["channel": BayeuxChannel.UNSUBSCRIBE_CHANNEL.description, "clientId": clientId, "subscription": channel, "ext": connectionExtension]
      let string = JSONStringify(dict)
      self.transport?.writeString(string)
    }
  }
  
  // Bayeux Publish
  // {
  // "channel": "/some/channel",
  // "clientId": "Un1q31d3nt1f13r",
  // "data": "some application string or JSON encoded object",
  // "id": "some unique message id"
  // }
  func publish(data:[String:AnyObject], channel:String){
    if(self.fayeConnected == true){
      let dict:[String:AnyObject] = ["channel": channel, "clientId": self.fayeClientId!, "id": self.nextMessageId(), "data": data, "ext": connectionExtension]
      
      let string = JSONStringify(dict)
      print("THIS IS THE PUBSLISH STRING: \(string)")
      self.transport?.writeString(string)
    }else{
      // Faye is not connected
    }
  }
}

// MARK: Private Internal methods
private extension FayeClient {
  func subscribeQueuedSubscriptions(){
    // if there are any outstanding open subscriptions resubscribe
    if(self.queuedSubscriptions.count > 0){
      let queue:NSSet = self.queuedSubscriptions.copy() as! NSSet
      
      for channel in queue{
        self.queuedSubscriptions.removeObject(channel)
        self.subscribe(channel as! String)
      }
    }
  }
  
  func send(message: NSDictionary){
    // Parse JSON
    do {
      let jsonData:NSData = try! NSJSONSerialization.dataWithJSONObject(message, options:[])
      let jsonString:NSString = NSString(data: jsonData, encoding:NSUTF8StringEncoding)!
      self.transport?.writeString(jsonString as String)
    } catch let error as NSError {
      print("[Send Message] Couldn't Parse JSON: \(error.localizedDescription)")
    } catch {
      print("[Send Message]: Unknown error")
    }
  }
  
  func receive(message: String){
    // Parse JSON
    let jsonData = message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
    let json = JSON(data: jsonData!)
    self.parseFayeMessage(json)
  }
  
  // http://iosdevelopertips.com/swift-code/base64-encode-decode-swift.html
  func nextMessageId() -> String{
    self.messageNumber++
    if(self.messageNumber >= UINT32_MAX){
      messageNumber = 0
    }
    let str = "\(self.messageNumber)"
    print("Original: \(str)")
    
    // UTF 8 str from original
    // NSData! type returned (optional)
    let utf8str = str.dataUsingEncoding(NSUTF8StringEncoding)
    
    // Base64 encode UTF 8 string
    // fromRaw(0) is equivalent to objc 'base64EncodedStringWithOptions:0'
    // Notice the unwrapping given the NSData! optional
    // NSString! returned (optional)
    let base64Encoded = utf8str?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
    print("Encoded:  \(base64Encoded)")
    
    // Base64 Decode (go back the other way)
    // Notice the unwrapping given the NSString! optional
    // NSData returned
    let data = NSData(base64EncodedString: base64Encoded!, options: NSDataBase64DecodingOptions())
    
    // Convert back to a string
    let base64Decoded = NSString(data: data!, encoding: NSUTF8StringEncoding)
    print("Decoded:  \(base64Decoded)")
    
    return base64Decoded! as String
  }
  
  // JSON Helpers
  func JSONStringify(jsonObj: AnyObject) -> String {
    do {
      let jsonData:NSData = try! NSJSONSerialization.dataWithJSONObject(jsonObj, options:NSJSONWritingOptions(rawValue: 0))
      return NSString(data: jsonData, encoding: NSUTF8StringEncoding)! as String
    } catch let error as NSError {
      print("[JSONStringify] Couldn't Parse JSON: \(error.localizedDescription)")
    } catch {
      return ""
    }
  }
}