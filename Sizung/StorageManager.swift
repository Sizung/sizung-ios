//
//  Storage.swift
//  Sizung
//
//  Created by Markus Klepp on 20/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Foundation
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
  let organizationDeliverables: CollectionProperty <[Deliverable]> = CollectionProperty([])
  let conversationDeliverables: CollectionProperty <[Deliverable]> = CollectionProperty([])
  
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
  
  func updateOrganizations() {
    
    self.isLoading.value = true
    Alamofire.request(SizungHttpRouter.Organizations())
      .validate()
      .responseJSON { response in
        switch response.result {
        case .Success(let JSON):
          if let organizationResponse = Mapper<OrganizationsResponse>().map(JSON) {
            self.organizations.replace(organizationResponse.data, performDiff: true)
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
            self.organizations.replace([organizationResponse.data], performDiff: true)
            self.conversations.replace(organizationResponse.meta.conversations.data, performDiff: true)
            self.agendaItems.replace(organizationResponse.meta.agendaItems.data, performDiff: true)
            
            let newDeliverables = organizationResponse.meta.deliverables.data + organizationResponse.meta.conversationDeliverables.data
            self.organizationDeliverables.replace(newDeliverables, performDiff: true)
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
            
//            self.conversationDeliverables.replace(newDeliverables, performDiff: true)
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
}