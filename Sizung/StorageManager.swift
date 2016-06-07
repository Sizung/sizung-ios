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

extension CollectionPropertyType where Collection == Array<Member>, Member : Equatable, Member : Hashable {
  public func insertOrUpdate(newCollection: [Self.Member]){
    var inserts: [Int] = []
    var updates: [Int] = []
    
    inserts.reserveCapacity(newCollection.count)
    updates.reserveCapacity(collection.count)
    
    let newSet = Set(newCollection)
    let currentSet = Set(collection)
    
    let newElements = newSet.subtract(currentSet)
    let updatedElements = currentSet.intersect(newSet)
    
    for newElement in newElements {
      inserts.append(newCollection.indexOf(newElement)!)
    }
    
    for updatedElement in updatedElements {
      updates.append(newCollection.indexOf(updatedElement)!)
    }
    
    update(CollectionChangeset(collection: newCollection, inserts: inserts, deletes: [], updates: updates))
  }
}

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
}