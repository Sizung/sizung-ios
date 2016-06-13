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
  let conversationObjects: CollectionProperty <[BaseModel]> = CollectionProperty([])
  
  let organizationUsers: CollectionProperty <[User]> = CollectionProperty([])
  
  func reset() {
    isInitialized = false
    isLoading.value = false
    organizations.removeAll()
    conversations.removeAll()
    agendaItems.removeAll()
    deliverables.removeAll()
  }
  
  func getOrganization(id: String) -> Organization? {
    let foundOrganizations = organizations.collection.filter { organization in
      organization.id == id
    }
    
    return foundOrganizations.first
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
      .responseJSON { response in
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
      .responseJSON { response in
        switch response.result {
        case .Success(let JSON):
          if let organizationResponse = Mapper<OrganizationResponse>().map(JSON) {
            self.conversations.insertOrUpdate(organizationResponse.conversationsResponse.conversations)
            self.agendaItems.insertOrUpdate(organizationResponse.agendaItemsResponse.agendaItems)
            
            self.deliverables.insertOrUpdate(organizationResponse.deliverablesResponse.deliverables)
            self.deliverables.insertOrUpdate(organizationResponse.conversationDeliverablesResponse.deliverables)
            
            for include in organizationResponse.included {
              switch include {
              case let user as User:
                self.organizationUsers.insertOrUpdate([user])
              default:
                print("unknown \(include)")
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
      .responseJSON { response in
        switch response.result {
        case .Success(let JSON):
          if let conversationResponse = Mapper<ConversationResponse>().map(JSON) {
            
            self.agendaItems.insertOrUpdate(conversationResponse.conversation.agenda_items)
            self.deliverables.insertOrUpdate(conversationResponse.conversation.deliverables)
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
  
  func updateConversationObjects(conversationId: String) {
    self.isLoading.value = true
    Alamofire.request(SizungHttpRouter.ConversationObjects(id: conversationId))
      .validate()
      .responseJSON { response in
        switch response.result {
        case .Success(let JSON):
          if let conversationObjectsResponse = Mapper<ConversationObjectsResponse>().map(JSON) {
            
            let comments = conversationObjectsResponse.conversationObjects.filter { obj in
              obj is Comment
            }
            
            self.conversationObjects.insertOrUpdate(comments)
            
//            for obj in conversationResponse.conversationObjects {
//              switch obj {
//              case let comment as Comment:
//                self.conversationObjects.insert(comment)
//              case let agendaItem as AgendaItem:
//                print("convObj deliverable \(agendaItem)")
//              case let deliverable as Deliverable:
//                print("convObj deliverable \(deliverable)")
//              default:
//                print("convObj: \(obj)")
//              }
//            }
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
  
  func createComment(comment: Comment){
    Alamofire.request(SizungHttpRouter.Comments(comment: comment))
      .validate()
      .responseJSON { response in
        switch response.result {
        case .Success(let JSON):
          if let commentResponse = Mapper<CommentResponse>().map(JSON) {
//            self.conversationObjects.insertOrUpdate([commentResponse.comment])
            self.updateConversationObjects(commentResponse.comment.commentable.id)
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