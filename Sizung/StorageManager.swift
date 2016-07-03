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
    if let orgId = Configuration.getSelectedOrganization() {
      return storageForOrganizationId(orgId)
    } else {
      let promise = Promise<OrganizationStorageManager, StorageError>()
      promise.failure(.Other)
      return promise.future
    }
  }

  private static func storageForOrganizationId(itemId: String) -> Future<OrganizationStorageManager, StorageError> {
    let promise = Promise<OrganizationStorageManager, StorageError>()

    if let storage = storages[itemId] {
      promise.success(storage)
    } else {
      initOrganizationStorageManager(itemId)
        .onSuccess { orgStorageManager in
          storages[itemId] = orgStorageManager
          promise.success(orgStorageManager)
      }
    }

    return promise.future
  }

  // Singleton
  static let sharedInstance = StorageManager()
  private init() {}

  // networking queue
  static let networkQueue = dispatch_queue_create("\(NSBundle.mainBundle().bundleIdentifier).networking-queue", DISPATCH_QUEUE_CONCURRENT)

  let unseenObjects: CollectionProperty <Set<UnseenObject>> = CollectionProperty([])
  var websocket: Websocket?

  func reset() {
    unseenObjects.replace([])
    StorageManager.storages = [:]
  }

  private static func makeRequest<T: Mappable>(urlRequest: URLRequestConvertible) -> Future<T, StorageError> {
    let promise = Promise<T, StorageError>()

    Alamofire.request(urlRequest)
      .validate()
      .responseJSON(queue: StorageManager.networkQueue) { response in
        switch response.result {
        case .Success(let JSON):
          if let typedResponse = Mapper<T>().map(JSON) {
            dispatch_async(dispatch_get_main_queue()) {
              promise.success(typedResponse)
            }
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.NotificationConstants.kNotificationKeyAuthError, object: nil)
          promise.failure(.NotAuthenticated)
        case .Failure
          where response.response?.statusCode == 404:
          promise.failure(.NotFound)
        case .Failure:
          Error.log(response.result.error!)
          promise.failure(.Other)
        }
    }

    return promise.future
  }

  static func initOrganizationStorageManager(organizationId: String) -> Future<OrganizationStorageManager, StorageError> {
    let promise = Promise<OrganizationStorageManager, StorageError>()

    makeRequest(SizungHttpRouter.Organization(id: organizationId))
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

    StorageManager.makeRequest(SizungHttpRouter.Organizations())
      .onSuccess { (organizationsResponse: OrganizationsResponse) in
        promise.success(organizationsResponse.organizations)
      }.onFailure { error in
        promise.failure(error)
    }

    return promise.future
  }


  func listUnseenObjects(userId: String) -> Future<[UnseenObject], StorageError> {
    let promise = Promise<[UnseenObject], StorageError>()

    StorageManager.makeRequest(SizungHttpRouter.UnseenObjects(userId: userId))
      .onSuccess { (unseenObjectsResponse: UnseenObjectsResponse) in
        let unseenObjects = unseenObjectsResponse.unseenObjects
        promise.success(unseenObjects)
        unseenObjects.forEach { unseenObject in
          self.unseenObjects.insert(unseenObject)
        }
      }.onFailure { error in
        promise.failure(error)
    }
    return promise.future
  }

  func sawTimeLineFor(object: BaseModel) -> Future<[UnseenObject], StorageError> {
    let promise = Promise<[UnseenObject], StorageError>()

    StorageManager.makeRequest(SizungHttpRouter.DeleteUnseenObjects(type: object.type, id: object.id))
      .onSuccess { (unseenObjectsResponse: UnseenObjectsResponse) in
        unseenObjectsResponse.unseenObjects.forEach { unseenObject in
          self.unseenObjects.remove(unseenObject)
        }
        promise.success(unseenObjectsResponse.unseenObjects)
      }.onFailure { error in
        promise.failure(error)
    }

    return promise.future
  }

  func getAgendaItem(itemId: String) -> Future<AgendaItem, StorageError> {
    let promise = Promise<AgendaItem, StorageError>()
    StorageManager.makeRequest(SizungHttpRouter.AgendaItem(id: itemId))
      .onSuccess { (agendaItemResponse: AgendaItemResponse) in
        promise.success(agendaItemResponse.agendaItem)
      }.onFailure { error in
        promise.failure(error)
    }
    return promise.future
  }

  func getDeliverable(itemId: String) -> Future<Deliverable, StorageError> {
    let promise = Promise<Deliverable, StorageError>()

    StorageManager.makeRequest(SizungHttpRouter.Deliverable(id: itemId))
      .onSuccess { (deliverableResponse: DeliverableResponse) in
        promise.success(deliverableResponse.deliverable)
      }.onFailure { error in
        promise.failure(error)
    }

    return promise.future
  }

  func getConversation(itemId: String) -> Future<Conversation, StorageError> {
    let promise = Promise<Conversation, StorageError>()

    StorageManager.makeRequest(SizungHttpRouter.Conversation(id: itemId))
      .onSuccess { (conversationResponse: ConversationResponse) in
        promise.success(conversationResponse.conversation)
      }.onFailure { error in
        promise.failure(error)
    }

    return promise.future
  }
}

class OrganizationStorageManager {

  let organization: Organization!

  private init(organization: Organization) {
    self.organization = organization
  }

  let conversations: CollectionProperty <[Conversation]> = CollectionProperty([])
  let agendaItems: CollectionProperty <[AgendaItem]> = CollectionProperty([])
  let deliverables: CollectionProperty <[Deliverable]> = CollectionProperty([])

  let users: CollectionProperty <[User]> = CollectionProperty([])

  func getConversation(itemId: String) -> Future<Conversation, StorageError> {
    let promise = Promise<Conversation, StorageError>()
    let foundConversations = conversations.collection.filter { conversation in
      conversation.id == itemId
    }

    if let foundConversation = foundConversations.first {
      promise.success(foundConversation)
    } else {
      StorageManager.makeRequest(SizungHttpRouter.Conversation(id: itemId))
        .onSuccess { (conversationResponse: ConversationResponse) in

          let conversation = conversationResponse.conversation
          self.conversations.insertOrUpdate([conversation])

          self.agendaItems.insertOrUpdate(conversation.agendaItems)
          self.deliverables.insertOrUpdate(conversation.deliverables)

          promise.success(conversation)

        }.onFailure { error in
          promise.failure(error)
      }
    }

    return promise.future
  }

  func getDeliverable(itemId: String) -> Future<Deliverable, StorageError> {
    let promise = Promise<Deliverable, StorageError>()

    let foundDeliverables = deliverables.collection.filter { deliverable in
      deliverable.id == itemId
    }

    if let foundDeliverable = foundDeliverables.first {
      promise.success(foundDeliverable)
    } else {
      StorageManager.sharedInstance.getDeliverable(itemId)
        .onSuccess { deliverable in

          self.deliverables.insertOrUpdate([deliverable])
          promise.success(deliverable)
        }.onFailure { error in
          promise.failure(error)
      }
    }

    return promise.future
  }

  func getAgendaItem(itemId: String) -> Future<AgendaItem, StorageError> {
    let promise = Promise<AgendaItem, StorageError>()
    let foundAgendaItems = agendaItems.collection.filter { agendaItem in
      agendaItem.id == itemId
    }

    if let foundAgendaItem = foundAgendaItems.first {
      promise.success(foundAgendaItem)
    } else {
      StorageManager.sharedInstance.getAgendaItem(itemId)
        .onSuccess { agendaItem in
          self.agendaItems.insertOrUpdate([agendaItem])
          promise.success(agendaItem)
        }.onFailure { error in
          promise.failure(error)
      }
    }

    return promise.future
  }

  func getUser(itemId: String) -> Future<User, StorageError> {
    let promise = Promise<User, StorageError>()

    let foundUsers = self.users.collection.filter { user in
      user.id == itemId
    }
    if let foundUser = foundUsers.first {
      promise.success(foundUser)
    } else {
      self.listUsers()
        .onSuccess { users in
          let foundUsers = self.users.collection.filter { user in
            user.id == itemId
          }
          if let foundUser = foundUsers.first {
            promise.success(foundUser)
          } else {
            promise.failure(StorageError.NotFound)
          }
        }.onFailure { _ in
          promise.failure(StorageError.Other)
        }.onFailure { error in
          promise.failure(error)
      }

    }
    return promise.future
  }

  func listUsers() -> Future<[User], StorageError> {
    let promise = Promise<[User], StorageError>()
    StorageManager.makeRequest(SizungHttpRouter.Organization(id: self.organization.id))
      .onSuccess { (organizationResponse: OrganizationResponse) in
        let filteredItems = organizationResponse.included.filter { $0 is User }

        if let users = filteredItems as? [User] {
          self.users.insertOrUpdate(users)
          promise.success(users)
        } else {
          // this should never happen, because we filter for users
          fatalError()
        }
      }.onFailure { error in
        promise.failure(error)
    }
    return promise.future
  }

  func listAgendaItems() -> Future<[AgendaItem], StorageError> {
    let promise = Promise<[AgendaItem], StorageError>()
    StorageManager.makeRequest(SizungHttpRouter.Organization(id: self.organization.id))
      .onSuccess { (organizationResponse: OrganizationResponse) in
        let agendaItems = organizationResponse.agendaItemsResponse.agendaItems

        self.agendaItems.insertOrUpdate(agendaItems)

        promise.success(agendaItems)
      }.onFailure { error in
        promise.failure(error)
    }

    return promise.future
  }

  func listDeliverables() -> Future<[Deliverable], StorageError> {
    let promise = Promise<[Deliverable], StorageError>()
    StorageManager.makeRequest(SizungHttpRouter.Organization(id: self.organization.id))
      .onSuccess { (organizationResponse: OrganizationResponse) in

        let newDeliverables = organizationResponse.deliverablesResponse.deliverables + organizationResponse.conversationDeliverablesResponse.deliverables

        self.deliverables.insertOrUpdate(newDeliverables)

        promise.success(newDeliverables)
      }.onFailure { error in
        promise.failure(error)
    }
    return promise.future
  }

  func listConversations() -> Future<[Conversation], StorageError> {
    let promise = Promise<[Conversation], StorageError>()
    StorageManager.makeRequest(SizungHttpRouter.Organization(id: self.organization.id))
      .onSuccess { (organizationResponse: OrganizationResponse) in

        let conversations = organizationResponse.conversationsResponse.conversations

        self.conversations.insertOrUpdate(conversations)

        promise.success(conversations)
      }.onFailure { error in
        promise.failure(error)
    }
    return promise.future
  }

  // conversationObjects are handled per entity
  func updateConversationObjects(parent: BaseModel, page: Int) -> Future<([BaseModel], Int?), StorageError> {

    let promise = Promise<([BaseModel], Int?), StorageError>()

    StorageManager.makeRequest(SizungHttpRouter.ConversationObjects(parent: parent, page: page))
      .onSuccess { (conversationObjectsResponse: ConversationObjectsResponse) in
        promise.success((conversationObjectsResponse.conversationObjects, conversationObjectsResponse.nextPage))
      }.onFailure { error in
        promise.failure(error)
    }


    return promise.future
  }

  func createComment(comment: Comment) -> Future<Comment, StorageError> {
    let promise = Promise<Comment, StorageError>()
    StorageManager.makeRequest(SizungHttpRouter.Comments(comment: comment))
      .onSuccess { (commentResponse: CommentResponse) in
        promise.success(commentResponse.comment)
      }.onFailure { error in
        promise.failure(error)
    }
    return promise.future
  }

  func updateDeliverable(deliverable: Deliverable) -> Future<Deliverable, StorageError> {
    let promise = Promise<Deliverable, StorageError>()
    StorageManager.makeRequest(SizungHttpRouter.UpdateDeliverable(deliverable: deliverable))
      .onSuccess { (deliverableResponse: DeliverableResponse) in

        promise.success(deliverableResponse.deliverable)
      }.onFailure { error in
        promise.failure(error)
    }
    return promise.future
  }

  func updateAgendaItem(agendaItem: AgendaItem) -> Future<AgendaItem, StorageError> {
    let promise = Promise<AgendaItem, StorageError>()
    StorageManager.makeRequest(SizungHttpRouter.UpdateAgendaItem(agendaItem: agendaItem))
      .onSuccess { ( agendaItemResponse: AgendaItemResponse ) in
        promise.success(agendaItemResponse.agendaItem)
      }.onFailure { error in
        promise.failure(error)
    }
    return promise.future
  }
}
