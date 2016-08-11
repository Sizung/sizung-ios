//
//  Storage.swift
//  Sizung
//
//  Created by Markus Klepp on 20/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ObjectMapper
import ReactiveKit
import BrightFutures
import SwiftKeychainWrapper

enum StorageError: ErrorType {
  case NotFound
  case NotAuthenticated
  case NonRecoverable
  case Other
}

class StorageManager {

  var storages: [String: OrganizationStorageManager] = [:]

  static func storageForSelectedOrganization() -> Future<OrganizationStorageManager, StorageError> {
    if let orgId = Configuration.getSelectedOrganization() {
      return sharedInstance.storageForOrganizationId(orgId)
    } else {
      let promise = Promise<OrganizationStorageManager, StorageError>()
      promise.failure(.Other)
      return promise.future
    }
  }

  func storageForOrganizationId(itemId: String) -> Future<OrganizationStorageManager, StorageError> {
    let promise = Promise<OrganizationStorageManager, StorageError>()

    if let storage = storages[itemId] {
      promise.success(storage)
    } else {
      StorageManager.initOrganizationStorageManager(itemId)
        .onSuccess { orgStorageManager in
          self.storages[itemId] = orgStorageManager
          promise.success(orgStorageManager)
        }.onFailure { error in
          promise.failure(error)
      }
    }

    return promise.future
  }

  // Singleton
  static let sharedInstance = StorageManager()
  private init() {}


  var websocket: Websocket?

  func reset() {
    storages = [:]
  }

  private static func initOrganizationStorageManager(organizationId: String) -> Future<OrganizationStorageManager, StorageError> {
    let promise = Promise<OrganizationStorageManager, StorageError>()

    NetworkManager.makeRequest(SizungHttpRouter.Organization(id: organizationId))
      .onSuccess { (organizationResponse: OrganizationResponse) in
        let organizationStorageManager = OrganizationStorageManager(organization: organizationResponse.organization)

        organizationStorageManager.conversations.insertOrUpdate(organizationResponse.conversationsResponse.conversations)
        organizationStorageManager.agendaItems.insertOrUpdate(organizationResponse.agendaItemsResponse.agendaItems)

        let deliverables = organizationResponse.deliverablesResponse.deliverables + organizationResponse.conversationDeliverablesResponse.deliverables

        organizationStorageManager.deliverables.insertOrUpdate(deliverables)

        for include in organizationResponse.included {
          switch include {
          case let user as User:
            organizationStorageManager.users.insertOrUpdate([user])
          case let member as OrganizationMember:
            organizationStorageManager.members.insertOrUpdate([member])
          default:
            break
          }
        }
        promise.success(organizationStorageManager)
      }.onFailure { error in
        promise.failure(error)
    }

    return promise.future
  }

  func listOrganizations() -> Future<[Organization], StorageError> {
    let promise = Promise<[Organization], StorageError>()

    NetworkManager.makeRequest(SizungHttpRouter.Organizations())
      .onSuccess { (organizationsResponse: OrganizationsResponse) in
        promise.success(organizationsResponse.organizations)
      }.onFailure { error in
        promise.failure(error)
    }

    return promise.future
  }


  func listUnseenObjectsForUser(userId: String, page: Int) -> Future<UnseenObjectsResponse, StorageError> {
    let promise = Promise<UnseenObjectsResponse, StorageError>()

    NetworkManager.makeRequest(SizungHttpRouter.UnseenObjectsForUser(userId: userId, page: page))
      .onSuccess { (unseenObjectsResponse: UnseenObjectsResponse) in
        promise.success(unseenObjectsResponse)
      }.onFailure { error in
        promise.failure(error)
    }
    return promise.future
  }

  func getAgendaItem(itemId: String) -> Future<AgendaItem, StorageError> {
    let promise = Promise<AgendaItem, StorageError>()
    NetworkManager.makeRequest(SizungHttpRouter.AgendaItem(id: itemId))
      .onSuccess { (agendaItemResponse: AgendaItemResponse) in
        promise.success(agendaItemResponse.agendaItem)
      }.onFailure { error in
        promise.failure(error)
    }
    return promise.future
  }

  func getDeliverable(itemId: String) -> Future<Deliverable, StorageError> {
    let promise = Promise<Deliverable, StorageError>()

    NetworkManager.makeRequest(SizungHttpRouter.Deliverable(id: itemId))
      .onSuccess { (deliverableResponse: DeliverableResponse) in
        promise.success(deliverableResponse.deliverable)
      }.onFailure { error in
        promise.failure(error)
    }

    return promise.future
  }

  func getConversation(itemId: String) -> Future<Conversation, StorageError> {
    let promise = Promise<Conversation, StorageError>()

    NetworkManager.makeRequest(SizungHttpRouter.Conversation(id: itemId))
      .onSuccess { (conversationResponse: ConversationResponse) in
        promise.success(conversationResponse.conversation)
      }.onFailure { error in
        promise.failure(error)
    }

    return promise.future
  }

  func createOrganization(name: String) -> Future<Organization, StorageError> {
    let promise = Promise<Organization, StorageError>()

    NetworkManager.makeRequest(SizungHttpRouter.CreateOrganization(name: name))
      .onSuccess { (organizationResponse: OrganizationResponse) in
        promise.success(organizationResponse.organization)
      }.onFailure { error in
        promise.failure(error)
    }

    return promise.future
  }

  func updateOrganization(organization: Organization) -> Future<Organization, StorageError> {
    let promise = Promise<Organization, StorageError>()

    NetworkManager.makeRequest(SizungHttpRouter.UpdateOrganization(organization: organization))
      .onSuccess { (organizationResponse: OrganizationResponse) in
        promise.success(organizationResponse.organization)
      }.onFailure { error in
        promise.failure(error)
    }

    return promise.future
  }
}
