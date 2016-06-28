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

enum StorageError: ErrorType {
  case NotFound
  case NotAuthenticated
  case Other
}

class StorageManager {
  
  static var storages: [String: OrganizationStorageManager] = [:]
  
  static func storageForSelectedOrganization() -> Future<OrganizationStorageManager, StorageError> {
    let orgId = KeychainWrapper.stringForKey(Configuration.Settings.SELECTED_ORGANIZATION)!
    return storageForOrganizationId(orgId)
  }
  
  private static func storageForOrganizationId(id: String) -> Future<OrganizationStorageManager, StorageError> {
    let promise = Promise<OrganizationStorageManager, StorageError>()
    
    if let storage = storages[id] {
      promise.success(storage)
    } else {
      initOrganizationStorageManager(id)
        .onSuccess { orgStorageManager in
          storages[id] = orgStorageManager
          promise.success(orgStorageManager)
      }
    }
    
    return promise.future
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
  
  static func initOrganizationStorageManager(id: String) -> Future<OrganizationStorageManager, StorageError> {
    let promise = Promise<OrganizationStorageManager, StorageError>()
    
    Alamofire.request(SizungHttpRouter.Organization(id: id))
      .validate()
      .responseJSON(queue: StorageManager.networkQueue) { response in
        switch response.result {
        case .Success(let JSON):
          if let organizationResponse = Mapper<OrganizationResponse>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              
              let organizationStorageManager = OrganizationStorageManager(organization: organizationResponse.organization)
              
              organizationStorageManager.conversations.insertOrUpdate(organizationResponse.conversationsResponse.conversations)
              organizationStorageManager.agendaItems.insertOrUpdate(organizationResponse.agendaItemsResponse.agendaItems)
              
              organizationStorageManager.deliverables.insertOrUpdate(organizationResponse.deliverablesResponse.deliverables)
              organizationStorageManager.deliverables.insertOrUpdate(organizationResponse.conversationDeliverablesResponse.deliverables)
              
              for include in organizationResponse.included {
                switch include {
                case let user as User:
                  organizationStorageManager.users.insertOrUpdate([user])
                default:
                  break;
                }
              }
              
              promise.success(organizationStorageManager)
            }
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
          promise.failure(StorageError.NotAuthenticated)
        default:
          print("error \(response.result)")
          promise.failure(StorageError.Other)
        }
    }
    return promise.future
  }
  
  func listUnseenObjects(userId: String) -> Future<[UnseenObject], StorageError> {
    let promise = Promise<[UnseenObject], StorageError>()
    
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
          promise.failure(StorageError.NotAuthenticated)
        default:
          print("error \(response.result)")
          promise.failure(StorageError.Other)
        }
    }
    
    return promise.future
  }
  
  func sawTimeLineFor(object: BaseModel) {
    Alamofire.request(SizungHttpRouter.DeleteUnseenObjects(type: object.type, id: object.id))
      .validate()
      .responseJSON(queue: StorageManager.networkQueue){ response in
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
  
  func getAgendaItem(id: String) -> Future<AgendaItem, StorageError> {
    let promise = Promise<AgendaItem, StorageError>()
    Alamofire.request(SizungHttpRouter.AgendaItem(id: id))
      .validate()
      .responseJSON(queue: StorageManager.networkQueue) {response in
        switch response.result {
        case .Success(let JSON):
          if let agendaItemResponse = Mapper<AgendaItemResponse>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              promise.success(agendaItemResponse.agendaItem)
            }
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
          promise.failure(StorageError.NotAuthenticated)
        default:
          print("error \(response.result)")
          promise.failure(StorageError.Other)
        }
    }
    return promise.future
  }
  
  func getDeliverable(id: String) -> Future<Deliverable, StorageError> {
    let promise = Promise<Deliverable, StorageError>()
    
    Alamofire.request(SizungHttpRouter.Deliverable(id: id))
      .validate()
      .responseJSON(queue: StorageManager.networkQueue) {response in
        switch response.result {
        case .Success(let JSON):
          if let deliverableResponse = Mapper<DeliverableResponse>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              promise.success(deliverableResponse.deliverable)
            }
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
          promise.failure(StorageError.NotAuthenticated)
        default:
          print("error \(response.result)")
          promise.failure(StorageError.Other)
        }
    }
    
    return promise.future
  }
  
  func getConversation(id: String) -> Future<Conversation, StorageError> {
    let promise = Promise<Conversation, StorageError>()
    
    Alamofire.request(SizungHttpRouter.Conversation(id: id))
      .validate()
      .responseJSON(queue: StorageManager.networkQueue) {response in
        switch response.result {
        case .Success(let JSON):
          if let conversationResponse = Mapper<ConversationResponse>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              promise.success(conversationResponse.conversation)
            }
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
          promise.failure(StorageError.NotAuthenticated)
        default:
          print("error \(response.result)")
          promise.failure(StorageError.Other)
        }
    }
    
    return promise.future
  }
}

class OrganizationStorageManager {
  
  let organization: Organization!
  
  private init(organization: Organization){
    self.organization = organization
  }
  
  let conversations: CollectionProperty <[Conversation]> = CollectionProperty([])
  let agendaItems: CollectionProperty <[AgendaItem]> = CollectionProperty([])
  let deliverables: CollectionProperty <[Deliverable]> = CollectionProperty([])
  
  let users: CollectionProperty <[User]> = CollectionProperty([])
  
  func getConversation(id: String) -> Future<Conversation, StorageError> {
    let promise = Promise<Conversation, StorageError>()
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
            promise.failure(StorageError.NotAuthenticated)
          default:
            print("error \(response.result)")
            promise.failure(StorageError.Other)
          }
      }
    }
    
    return promise.future
  }
  
  func getDeliverable(id: String) -> Future<Deliverable, StorageError> {
    let promise = Promise<Deliverable, StorageError>()
    
    let foundDeliverables = deliverables.collection.filter { deliverable in
      deliverable.id == id
    }
    
    if let foundDeliverable = foundDeliverables.first {
      promise.success(foundDeliverable)
    } else {
      StorageManager.sharedInstance.getDeliverable(id)
        .onSuccess { deliverable in
          
          self.deliverables.insertOrUpdate([deliverable])
          promise.success(deliverable)
      }
    }
    
    return promise.future
  }
  
  func getAgendaItem(id: String) -> Future<AgendaItem, StorageError> {
    let promise = Promise<AgendaItem, StorageError>()
    let foundAgendaItems = agendaItems.collection.filter { agendaItem in
      agendaItem.id == id
    }
    
    if let foundAgendaItem = foundAgendaItems.first {
      promise.success(foundAgendaItem)
    } else {
      StorageManager.sharedInstance.getAgendaItem(id)
        .onSuccess { agendaItem in
          self.agendaItems.insertOrUpdate([agendaItem])
          promise.success(agendaItem)
      }
    }
    
    return promise.future
  }
  
  func getUser(id: String) -> Future<User, StorageError> {
    let promise = Promise<User, StorageError>()
    
    let foundUsers = self.users.collection.filter { user in
      user.id == id
    }
    if let foundUser = foundUsers.first {
      promise.success(foundUser)
    } else {
      self.listUsers()
        .onSuccess { users in
          let foundUsers = self.users.collection.filter { user in
            user.id == id
          }
          if let foundUser = foundUsers.first {
            promise.success(foundUser)
          } else {
            promise.failure(StorageError.NotFound)
          }
        }.onFailure { _ in
          promise.failure(StorageError.Other)
      }
      
    }
    return promise.future
  }
  
  func listUsers() -> Future<[User], StorageError> {
    let promise = Promise<[User], StorageError>()
    Alamofire.request(SizungHttpRouter.Organization(id: self.organization.id))
      .validate()
      .responseJSON(queue: StorageManager.networkQueue) { response in
        switch response.result {
        case .Success(let JSON):
          if let organizationResponse = Mapper<OrganizationResponse>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              let users = organizationResponse.included.filter { $0 is User } as! [User]
              
              self.users.insertOrUpdate(users)
              
              promise.success(users)
            }
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
          promise.failure(StorageError.NotAuthenticated)
        default:
          print("error \(response.result)")
          promise.failure(StorageError.Other)
        }
    }
    return promise.future
  }
  
  func listAgendaItems() -> Future<[AgendaItem], StorageError> {
    let promise = Promise<[AgendaItem], StorageError>()
    Alamofire.request(SizungHttpRouter.Organization(id: self.organization.id))
      .validate()
      .responseJSON(queue: StorageManager.networkQueue) { response in
        switch response.result {
        case .Success(let JSON):
          if let organizationResponse = Mapper<OrganizationResponse>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              
              let agendaItems = organizationResponse.agendaItemsResponse.agendaItems
              
              self.agendaItems.insertOrUpdate(agendaItems)
              
              promise.success(agendaItems)
            }
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
          promise.failure(StorageError.NotAuthenticated)
        default:
          print("error \(response.result)")
          promise.failure(StorageError.Other)
        }
    }
    return promise.future
  }
  
  func listDeliverables() -> Future<[Deliverable], StorageError> {
    let promise = Promise<[Deliverable], StorageError>()
    Alamofire.request(SizungHttpRouter.Organization(id: self.organization.id))
      .validate()
      .responseJSON(queue: StorageManager.networkQueue) { response in
        switch response.result {
        case .Success(let JSON):
          if let organizationResponse = Mapper<OrganizationResponse>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              
              let newDeliverables = organizationResponse.deliverablesResponse.deliverables + organizationResponse.conversationDeliverablesResponse.deliverables
              
              self.deliverables.insertOrUpdate(newDeliverables)
              
              promise.success(newDeliverables)
            }
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
          promise.failure(StorageError.NotAuthenticated)
        default:
          print("error \(response.result)")
          promise.failure(StorageError.Other)
        }
    }
    return promise.future
  }
  
  func listConversations() -> Future<[Conversation], StorageError> {
    let promise = Promise<[Conversation], StorageError>()
    Alamofire.request(SizungHttpRouter.Organization(id: self.organization.id))
      .validate()
      .responseJSON(queue: StorageManager.networkQueue) { response in
        switch response.result {
        case .Success(let JSON):
          if let organizationResponse = Mapper<OrganizationResponse>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              
              let conversations = organizationResponse.conversationsResponse.conversations
              
              self.conversations.insertOrUpdate(conversations)
              
              promise.success(conversations)
            }
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
          promise.failure(StorageError.NotAuthenticated)
        default:
          print("error \(response.result)")
          promise.failure(StorageError.Other)
        }
    }
    return promise.future
  }
  
  func listOrganizations() -> Future<[Organization], StorageError> {
    let promise = Promise<[Organization], StorageError>()
    
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
          promise.failure(StorageError.NotAuthenticated)
        default:
          print("error \(response.result)")
          promise.failure(StorageError.Other)
        }
    }
    
    return promise.future
  }
  
  // conversationObjects are handled per entity
  func updateConversationObjects(parent: BaseModel, page: Int) -> Future<([BaseModel], Int?), StorageError>  {
    
    let promise = Promise<([BaseModel], Int?), StorageError>()
    
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
          promise.failure(StorageError.NotAuthenticated)
        default:
          print("error \(response.result)")
          promise.failure(StorageError.Other)
        }
    }
    
    
    return promise.future
  }
  
  func createComment(comment: Comment) -> Future<Comment, StorageError> {
    let promise = Promise<Comment, StorageError>()
    Alamofire.request(SizungHttpRouter.Comments(comment: comment))
      .validate()
      .responseJSON(queue: StorageManager.networkQueue) { response in
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
          promise.failure(StorageError.NotAuthenticated)
        default:
          print("error \(response.result)")
          promise.failure(StorageError.Other)
        }
    }
    return promise.future
  }
}
