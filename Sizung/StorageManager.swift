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

class StorageManager {
  //  singleton
  static let sharedInstance = StorageManager()
  private init() {}
  
  var isInitialized = false
  var isLoading = Property(false)
  
  let organizations: CollectionProperty <[Organization]> = CollectionProperty([])
  let conversations: CollectionProperty <[Conversation]> = CollectionProperty([])
  let agendaItems: CollectionProperty <[AgendaItem]> = CollectionProperty([])
  let deliverables: CollectionProperty <[Deliverable]> = CollectionProperty([])
  
  let organizationUsers: CollectionProperty <[User]> = CollectionProperty([])
  
  let unseenObjects: CollectionProperty <Set<UnseenObject>> = CollectionProperty([])
  
  var websocket: Websocket?
  
  // networking queue
  let networkQueue = dispatch_queue_create("\(NSBundle.mainBundle().bundleIdentifier).networking-queue", DISPATCH_QUEUE_CONCURRENT)
  
  func reset() {
    isInitialized = false
    isLoading.value = false
    organizations.removeAll()
    conversations.removeAll()
    agendaItems.removeAll()
    deliverables.removeAll()
    organizationUsers.removeAll()
    //    organizationMembers.removeAll()
  }
  
  func getOrganization(id: String) -> Organization? {
    let foundOrganizations = organizations.collection.filter { organization in
      organization.id == id
    }
    
    return foundOrganizations.first
  }
  
  func getConversation(id: String) -> Conversation? {
    let foundConversation = conversations.collection.filter { conversation in
      conversation.id == id
    }
    
    return foundConversation.first
  }
  
  func getDeliverable(id: String) -> Deliverable? {
    let foundDeliverable = deliverables.collection.filter { deliverable in
      deliverable.id == id
    }
    
    return foundDeliverable.first
  }
  
  func getAgendaItem(id: String) -> AgendaItem? {
    let foundAgendaItem = agendaItems.collection.filter { agendaItem in
      agendaItem.id == id
    }
    
    return foundAgendaItem.first
  }
  
  func fillConversation(item: Conversation?) -> Conversation? {
    let foundConversation = conversations.collection.filter { conversation in
      conversation.id == item?.id
    }
    
    return foundConversation.first
  }
  
  func fillDeliverable(item: Deliverable?) -> Deliverable? {
    let foundDeliverable = deliverables.collection.filter { deliverable in
      deliverable.id == item?.id
    }
    
    return foundDeliverable.first
  }
  
  func fillAgendaItem(item: AgendaItem?) -> AgendaItem? {
    let foundAgendaItem = agendaItems.collection.filter { agendaItem in
      agendaItem.id == item?.id
    }
    
    return foundAgendaItem.first
  }
  
  func getUser(id: String) -> User? {
    let foundUsers = organizationUsers.collection.filter { user in
      user.id == id
    }
    
    return foundUsers.first
  }
  
  func updateOrganizations() {
    
    self.isLoading.value = true
    Alamofire.request(SizungHttpRouter.Organizations())
      .validate()
      .responseJSON(queue: networkQueue) { response in
        switch response.result {
        case .Success(let JSON):
          if let organizationResponse = Mapper<OrganizationsResponse>().map(JSON) {
            self.organizations.insertOrUpdate(organizationResponse.organizations)
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
        default:
          print(response.response)
        }
        self.isLoading.value = false
    }
  }
  
  func updateOrganization(organizationId: String) {
    
    self.isLoading.value = true
    Alamofire.request(SizungHttpRouter.Organization(id: organizationId))
      .validate()
      .responseJSON(queue: networkQueue) { response in
        switch response.result {
        case .Success(let JSON):
          if let organizationResponse = Mapper<OrganizationResponse>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              self.organizations.insertOrUpdate([organizationResponse.organization])
              self.conversations.insertOrUpdate(organizationResponse.conversationsResponse.conversations)
              self.agendaItems.insertOrUpdate(organizationResponse.agendaItemsResponse.agendaItems)
              
              self.deliverables.insertOrUpdate(organizationResponse.deliverablesResponse.deliverables)
              self.deliverables.insertOrUpdate(organizationResponse.conversationDeliverablesResponse.deliverables)
              
              for include in organizationResponse.included {
                switch include {
                case let user as User:
                  self.organizationUsers.insertOrUpdate([user])
                default:
                  //                print("Unknown organization include \(include.type)")
                  break;
                }
              }
            }
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
        default:
          print("error \(response.result)")
        }
        self.isLoading.value = false
        self.isInitialized = true
    }
  }
  
  func updateConversation(conversationId: String) {
    self.isLoading.value = true
    Alamofire.request(SizungHttpRouter.Conversation(id: conversationId))
      .validate()
      .responseJSON(queue: networkQueue) {response in
        switch response.result {
        case .Success(let JSON):
          if let conversationResponse = Mapper<ConversationResponse>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              self.agendaItems.insertOrUpdate(conversationResponse.conversation.agenda_items)
              self.deliverables.insertOrUpdate(conversationResponse.conversation.deliverables)
            }
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
        default:
          print("error \(response.result)")
        }
        self.isLoading.value = false
        self.isInitialized = true
    }
  }
  
  // conversationObjects are handled per entity
  func updateConversationObjects(parent: BaseModel, page: Int) -> Future<([BaseModel], Int?), NSError>  {
    
    let promise = Promise<([BaseModel], Int?), NSError>()
    
    self.isLoading.value = true
    Alamofire.request(SizungHttpRouter.ConversationObjects(parent: parent, page: page))
      .validate()
      .responseJSON(queue: networkQueue) { response in
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
        self.isLoading.value = false
        self.isInitialized = true
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
  
  func updateUnseenObjects(userId: String) {
    Alamofire.request(SizungHttpRouter.UnseenObjects(userId: userId))
      .validate()
      .responseJSON(queue: networkQueue){ response in
        switch response.result {
        case .Success(let JSON):
          if let unseenObjectResponse = Mapper<UnseenObjectsResponse>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              unseenObjectResponse.unseenObjects.forEach { unseenObject in
                self.unseenObjects.insert(unseenObject)
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