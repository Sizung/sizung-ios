//
//  Storage.swift
//  Sizung
//
//  Created by Markus Klepp on 20/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Alamofire
import ObjectMapper
import ReactiveKit
import BrightFutures
import SwiftKeychainWrapper

class StorageManager {
  
  static var storages: [String: OrganizationStorageManager] = [:]
  
  static func storageForSelectedOrganization() -> OrganizationStorageManager {
    let orgId = KeychainWrapper.stringForKey(Configuration.Settings.SELECTED_ORGANIZATION)!
    return storageForOrganizationId(orgId)
  }
  
  static func storageForOrganizationId(id: String) -> OrganizationStorageManager {
    if storages[id] != nil {
      storages[id] = OrganizationStorageManager(organizationId: id)
    }
    return storages[id]!
  }
  
  // Singleton
  static let sharedInstance = StorageManager()
  private init(){}
  
  // networking queue
  static let networkQueue = dispatch_queue_create("\(NSBundle.mainBundle().bundleIdentifier).networking-queue", DISPATCH_QUEUE_CONCURRENT)
  
  let unseenObjects: CollectionProperty <Set<UnseenObject>> = CollectionProperty([])
  var websocket: Websocket?
  
  func reset() {
    unseenObjects.replace([])
    StorageManager.storages = [:]
  }
  
  func listUnseenObjects(userId: String) -> Future<[UnseenObject], NSError> {
    let promise = Promise<[UnseenObject], NSError>()
    
    Alamofire.request(SizungHttpRouter.UnseenObjects(userId: userId))
      .validate()
      .responseJSON(queue: StorageManager.networkQueue){ response in
        switch response.result {
        case .Success(let JSON):
          if let unseenObjectResponse = Mapper<UnseenObjectsResponse>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              promise.success(unseenObjectResponse.unseenObjects)
              unseenObjectResponse.unseenObjects.forEach { unseenObject in
                self.unseenObjects.insert(unseenObject)
              }
            }
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
          promise.failure(response.result.error!)
        default:
          print("error \(response.result)")
          promise.failure(response.result.error!)
        }
    }
    
    return promise.future
  }
}

class OrganizationStorageManager {
  
  let organization: Organization!
  
  private init(organizationId: String){
    getOrganization(organizationId)
      .onSuccess { self.organization = $0 }
  }
  
  let conversations: CollectionProperty <[Conversation]> = CollectionProperty([])
  let agendaItems: CollectionProperty <[AgendaItem]> = CollectionProperty([])
  let deliverables: CollectionProperty <[Deliverable]> = CollectionProperty([])
  
  let users: CollectionProperty <[User]> = CollectionProperty([])
  
  func getOrganization(id: String) -> Future<Organization, NSError> {
    let promise = Promise<Organization, NSError>()
    
    Alamofire.request(SizungHttpRouter.Organization(id: id))
      .validate()
      .responseJSON(queue: StorageManager.networkQueue) { response in
        switch response.result {
        case .Success(let JSON):
          if let organizationResponse = Mapper<OrganizationResponse>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              
              promise.success(organizationResponse.organization)
              
              self.conversations.insertOrUpdate(organizationResponse.conversationsResponse.conversations)
              self.agendaItems.insertOrUpdate(organizationResponse.agendaItemsResponse.agendaItems)
              
              self.deliverables.insertOrUpdate(organizationResponse.deliverablesResponse.deliverables)
              self.deliverables.insertOrUpdate(organizationResponse.conversationDeliverablesResponse.deliverables)
              
              for include in organizationResponse.included {
                switch include {
                case let user as User:
                  self.users.insertOrUpdate([user])
                default:
                  break;
                }
              }
            }
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
          promise.failure(response.result.error!)
        default:
          print("error \(response.result)")
          promise.failure(response.result.error!)
        }
    }
    return promise.future
  }
  
  func getConversation(id: String) -> Future<Conversation, NSError> {
    let promise = Promise<Conversation, NSError>()
    let foundConversations = conversations.collection.filter { conversation in
      conversation.id == id
    }
    
    if let foundConversation = foundConversations.first {
      promise.success(foundConversation)
    } else {
      Alamofire.request(SizungHttpRouter.Conversation(id: id))
        .validate()
        .responseJSON(queue: StorageManager.networkQueue) {response in
          switch response.result {
          case .Success(let JSON):
            if let conversationResponse = Mapper<ConversationResponse>().map(JSON) {
              dispatch_async(dispatch_get_main_queue()) {
                
                self.conversations.insertOrUpdate([conversationResponse.conversation])
                promise.success(conversationResponse.conversation)
                
                self.agendaItems.insertOrUpdate(conversationResponse.conversation.agenda_items)
                self.deliverables.insertOrUpdate(conversationResponse.conversation.deliverables)
              }
            }
          case .Failure
            where response.response?.statusCode == 401:
            NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
            promise.failure(response.result.error!)
          default:
            print("error \(response.result)")
            promise.failure(response.result.error!)
          }
      }
    }
    
    return promise.future
  }
  
  func getDeliverable(id: String) -> Future<Deliverable, NSError> {
    let promise = Promise<Deliverable, NSError>()
    
    let foundDeliverables = deliverables.collection.filter { deliverable in
      deliverable.id == id
    }
    
    if let foundDeliverable = foundDeliverables.first {
      promise.success(foundDeliverable)
    } else {
      Alamofire.request(SizungHttpRouter.Deliverable(id: id))
        .validate()
        .responseJSON(queue: StorageManager.networkQueue) {response in
          switch response.result {
          case .Success(let JSON):
            if let deliverableResponse = Mapper<DeliverableResponse>().map(JSON) {
              dispatch_async(dispatch_get_main_queue()) {
                
                self.deliverables.insertOrUpdate([deliverableResponse.deliverable])
                promise.success(deliverableResponse.deliverable)
              }
            }
          case .Failure
            where response.response?.statusCode == 401:
            NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
            promise.failure(response.result.error!)
          default:
            print("error \(response.result)")
            promise.failure(response.result.error!)
          }
      }
    }
    
    return promise.future
  }
  
  func getAgendaItem(id: String) -> Future<AgendaItem, NSError> {
    let promise = Promise<AgendaItem, NSError>()
    let foundAgendaItems = agendaItems.collection.filter { agendaItem in
      agendaItem.id == id
    }
    
    if let foundAgendaItem = foundAgendaItems.first {
      promise.success(foundAgendaItem)
    } else {
      Alamofire.request(SizungHttpRouter.AgendaItem(id: id))
        .validate()
        .responseJSON(queue: StorageManager.networkQueue) {response in
          switch response.result {
          case .Success(let JSON):
            if let agendaItemResponse = Mapper<AgendaItemResponse>().map(JSON) {
              dispatch_async(dispatch_get_main_queue()) {
                
                self.agendaItems.insertOrUpdate([agendaItemResponse.agendaItem])
                promise.success(agendaItemResponse.agendaItem)
              }
            }
          case .Failure
            where response.response?.statusCode == 401:
            NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
            promise.failure(response.result.error!)
          default:
            print("error \(response.result)")
            promise.failure(response.result.error!)
          }
      }
    }
    
    return promise.future
  }
  
  func getUser(id: String) -> Future<User, NSError> {
    let promise = Promise<User, NSError>()
    
    getOrganization(self.organization.id)
      .onSuccess { _ in
        let foundUsers = self.users.collection.filter { user in
          user.id == id
        }
        if let foundUser = foundUsers.first {
          promise.success(foundUser)
        } else {
          promise.failure()
        }
    }
    
    return promise.future
  }
  
  func listOrganizations() -> Future<[Organization], NSError> {
    let promise = Promise<[Organization], NSError>()
    
    Alamofire.request(SizungHttpRouter.Organizations())
      .validate()
      .responseJSON(queue: StorageManager.networkQueue) { response in
        switch response.result {
        case .Success(let JSON):
          if let organizationResponse = Mapper<OrganizationsResponse>().map(JSON) {
            promise.success(organizationResponse.organizations)
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
          promise.failure(response.result.error!)
        default:
          print(response.response)
          promise.failure(response.result.error!)
        }
    }
    
    return promise.future
  }
  
  // conversationObjects are handled per entity
  func updateConversationObjects(parent: BaseModel, page: Int) -> Future<([BaseModel], Int?), NSError>  {
    
    let promise = Promise<([BaseModel], Int?), NSError>()
    
    Alamofire.request(SizungHttpRouter.ConversationObjects(parent: parent, page: page))
      .validate()
      .responseJSON(queue: StorageManager.networkQueue) { response in
        switch response.result {
        case .Success(let JSON):
          if let conversationObjectsResponse = Mapper<ConversationObjectsResponse>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              promise.success((conversationObjectsResponse.conversationObjects, conversationObjectsResponse.nextPage))
            }
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
          dispatch_async(dispatch_get_main_queue()) {
            promise.failure(response.result.error!)
          }
        default:
          print("error \(response.result)")
          dispatch_async(dispatch_get_main_queue()) {
            promise.failure(response.result.error!)
          }
        }
    }
    
    
    return promise.future
  }
  
  func createComment(comment: Comment) -> Future<Comment, NSError> {
    let promise = Promise<Comment, NSError>()
    Alamofire.request(SizungHttpRouter.Comments(comment: comment))
      .validate()
      .responseJSON(queue: networkQueue) { response in
        switch response.result {
        case .Success(let JSON):
          if let commentResponse = Mapper<CommentResponse>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              promise.success(commentResponse.comment)
            }
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
          dispatch_async(dispatch_get_main_queue()) {
            promise.failure(response.result.error!)
          }
        default:
          print("error \(response.result)")
          dispatch_async(dispatch_get_main_queue()) {
            promise.failure(response.result.error!)
          }
        }
    }
    return promise.future
  }
  
  func sawTimeLineFor(object: BaseModel) {
    Alamofire.request(SizungHttpRouter.DeleteUnseenObjects(type: object.type, id: object.id))
      .validate()
      .responseJSON(queue: networkQueue){ response in
        switch response.result {
        case .Success(let JSON):
          if let unseenObjectResponse = Mapper<UnseenObjectsResponse>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              unseenObjectResponse.unseenObjects.forEach { unseenObject in
                self.unseenObjects.remove(unseenObject)
              }
            }
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
        default:
          print("error \(response.result)")
        }
    }
  }
}
