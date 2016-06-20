//
//  SizungRouter.swift
//  Sizung
//
//  Created by Markus Klepp on 13/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Alamofire
import ObjectMapper
import SwiftKeychainWrapper

enum SizungHttpRouter: URLRequestConvertible {
  
  case Login(email: String, password: String)
  case RegisterDevice(token: String)
  case Logout()
  case Organizations()
  case Organization(id: String)
  case Conversation(id: String)
  case ConversationObjects(parent: BaseModel, page: Int)
  case Comments(comment: Comment)
  
  
  var method: Alamofire.Method {
    switch self {
    case .Login,
         .RegisterDevice,
         .Comments:
      return .POST
    case .Logout:
      return .DELETE
    default:
      return .GET
    }
  }
  
  var path: String {
    switch self {
    case .Login,
         .Logout:
      return "/session_tokens"
    case .RegisterDevice:
      return "/devices"
    case .Organizations:
      return "/organizations"
    case .Organization(let id):
      return "/organizations/\(id)"
    case .Conversation(let id):
      return "/conversations/\(id)"
    case .ConversationObjects(let conversation as Sizung.Conversation, _):
      return "/conversations/\(conversation.id)/conversation_objects"
    case .ConversationObjects(let agendaItem as AgendaItem, _):
      return "/agenda_items/\(agendaItem.id)/conversation_objects"
    case .ConversationObjects(let deliverable as Deliverable, _):
      return "/deliverables/\(deliverable.id)/conversation_objects"
    case .ConversationObjects:
      fatalError("unkown router call to .ConversationObjects")
    case .Comments:
      return "/comments"
    }
  }
  
  var authentication: String? {
    switch self {
    case .Login:
      return nil
    default:
      if let authToken = KeychainWrapper.stringForKey(Configuration.Settings.AUTH_TOKEN) {
        return "Bearer \(authToken))"
      }else {
        return nil
      }
    }
  }
  
  var jsonParameters: [String: AnyObject]? {
    switch self {
    case .Login(let email, let password):
      return [
        "user": [
          "email": email,
          "password": password
        ]
      ]
    case .RegisterDevice(let deviceToken):
      return [
        "device": [
          "token": deviceToken
        ]
      ]
    case .Comments(let comment):
      
      // TODO: workaround for incorrect type
      let commentableType = String(comment.commentable.type.capitalizedString.characters.dropLast()).stringByReplacingOccurrencesOfString("_", withString: "")
      return [
        "comment": [
          "commentable_id": comment.commentable.id,
          "commentable_type": commentableType,
          "body": comment.body
        ]
      ]
    default:
      return nil
    }
  }
  
  var urlParams: [String: AnyObject]? {
    switch self {
    case .ConversationObjects(_, let page):
      return [
        "page[number]": page,
        "page[size]": 20
      ]
    default:
      return nil
    }
  }
  
  // MARK: URLRequestConvertible
  
  var URLRequest: NSMutableURLRequest {
    
    let URL = NSURL(string: Configuration.APIEndpoint())!
    let mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(path))
    mutableURLRequest.HTTPMethod = method.rawValue
    mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    mutableURLRequest.setValue(Configuration.getDeviceId(), forHTTPHeaderField: "X-DEVICE")
    
    mutableURLRequest.setValue(self.authentication, forHTTPHeaderField: "Authorization")
    
    switch self {
    case .Login,
         .RegisterDevice,
         .Comments:
      return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: self.jsonParameters).0
    case .ConversationObjects:
      return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: self.urlParams).0
    default:
      return mutableURLRequest
    }
  }
}