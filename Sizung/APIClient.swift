//
//  NetworkClient.swift
//  Sizung
//
//  Created by Markus Klepp on 20/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
import Spine
import SwiftKeychainWrapper
import Result
import BrightFutures

enum APIError : ErrorType {
  case Unauthorized
  case NotFound
  case UnknownError
}

class APIClient {
  
  let spine: Spine
  
  init(){
    let baseURL = NSURL(string: Configuration.APIEndpoint())
    spine = Spine(baseURL: baseURL!)
    
    //  Set log level
    Spine.setLogLevel(.Debug, forDomain: .Spine)
    Spine.setLogLevel(.Debug, forDomain: .Networking)
    Spine.setLogLevel(.Debug, forDomain: .Serializing)
    
    //  get auth token and set it
    if let authToken = KeychainWrapper.standardKeychainAccess().stringForKey(Configuration.Settings.AUTH_TOKEN) {
      (spine.networkClient as! HTTPClient).setHeader("Authorization", to: "Bearer \(authToken)")
    }
    
    (spine.networkClient as! HTTPClient).setHeader("Accept", to: "application/json")
    
    //  register models
    spine.registerResource(Organization)
    spine.registerResource(Conversation)
    spine.registerResource(OrganizationMember)
    spine.registerResource(User)
    spine.registerResource(AgendaItem)
    spine.registerResource(AgendaItemDeliverable)
    spine.registerResource(Deliverable)
    spine.registerResource(ConversationMember)
    spine.registerResource(Comment)
  }
  
  func getOrganizations() -> Future<[Organization], APIError> {
    let promise = Promise<[Organization], APIError>()
    
    spine.findAll(Organization)
      .onSuccess { (resources, meta, jsonapi) in
        let organizations = resources.resources as! [Organization]
        promise.success(organizations)
      }
      .onFailure { (error) in
        print("getOrganizations error: \(error)")
//        TODO: use real error handling
        switch error._code {
        case 401:
          promise.failure(APIError.Unauthorized)
        default:
          promise.failure(APIError.Unauthorized)
        }
    }
    
    
    return promise.future
  }
  
  func getConversations(organizationId: String) -> Future<[Conversation], APIError> {
    let promise = Promise<[Conversation], APIError>()
    
    let query = Query(resourceType: Conversation.self, path: "api/organizations/\(organizationId)/conversations")
    spine.find(query)
      .onSuccess { (resources, meta, jsonapi) in
        let conversations = resources.resources as! [Conversation]
        promise.success(conversations)
      }
      .onFailure { (error) in
        print("getConversations error: \(error)")
        //        TODO: use real error handling
        switch error._code {
        case 401:
          promise.failure(APIError.Unauthorized)
        default:
          promise.failure(APIError.Unauthorized)
        }
    }
    
    
    return promise.future
  }
  
  func getConversationObjects(conversationId: String) -> Future<[Resource], APIError> {
    let promise = Promise<[Resource], APIError>()
    
    let query = Query(resourceType: Conversation.self, path: "api/conversations/\(conversationId)/conversation_objects")
    spine.find(query)
      .onSuccess { (resources, meta, jsonapi) in
        let conversationObjects = resources.resources
        promise.success(conversationObjects)
      }
      .onFailure { (error) in
        print("getConversations error: \(error)")
        //        TODO: use real error handling
        switch error._code {
        case 401:
          promise.failure(APIError.Unauthorized)
        default:
          promise.failure(APIError.Unauthorized)
        }
    }
    
    return promise.future
  }
  

  
//  func getOrganization(organizationId: String) -> Future<Organization, APIError> {
//    
//    let promise = Promise<Organization, APIError>()
//    
//    spine.findOne(organizationId, ofType: Organization.self)
//      .onSuccess { (organization, meta, jsonapi) in
//        if let conversationsDictionary = meta?["conversations"] {
//          let conversationsData = NSKeyedArchiver.archivedDataWithRootObject(conversationsDictionary)
//          print("conversations: \(conversationsData)")
//          let document =  try! self.spine.serializer.deserializeData(conversationsData)
//          print(document)
////          organization.conversations?.appendResources(conversations)
//        }
//        promise.success(organization)
//      }
//      .onFailure { (error) in
//        print("getOrganization error: \(error)")
//    }
//    
//    return promise.future
//  }
  
}
