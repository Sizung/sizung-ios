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

  // networking queue
  static let networkQueue = dispatch_queue_create("\(NSBundle.mainBundle().bundleIdentifier).networking-queue", DISPATCH_QUEUE_CONCURRENT)

  let unseenObjects: CollectionProperty <[UnseenObject]> = CollectionProperty([])
  var websocket: Websocket?

  func reset() {
    unseenObjects.replace([])
    storages = [:]
  }

  static func makeRequest<T: Mappable>(urlRequest: URLRequestConvertible) -> Future<T, StorageError> {
    let promise = Promise<T, StorageError>()

    Alamofire.request(urlRequest)
      .validate()
      .responseJSON(queue: StorageManager.networkQueue) { response in
        switch response.result {
        case .Success(let JSON):
          if let typedResponse = Mapper<T>().map(JSON) {
            promise.success(typedResponse)
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.NotificationConstants.kNotificationKeyAuthError, object: nil)
          promise.failure(.NotAuthenticated)
        case .Failure
          where response.response?.statusCode == 404:
          promise.failure(.NotFound)
        case .Failure
          where response.response?.statusCode == 500:
          promise.failure(.NonRecoverable)
        case .Failure:
          if let error = response.result.error {
            switch error.code {
            // only log certain errors
            case -1001, // Timeout
            -1018: //  International roaming is currently off
              Log.error(error, response.request?.URLString).send()
            // report the rest
            default:
              var userInfo = error.userInfo
              if let originalLocalizedDescription = userInfo[NSLocalizedDescriptionKey] {
                userInfo[NSLocalizedDescriptionKey] = "\(originalLocalizedDescription) url: \(response.request?.URLString)"
              } else {
                userInfo[NSLocalizedDescriptionKey] = "failed for url: \(response.request?.URLString)"
              }

              let newError = NSError(domain: error.domain, code: error.code, userInfo: userInfo)
              Error.log(newError)
            }
          } else {
            Error.log("Something failed")
          }
          promise.failure(.Other)
        }
    }

    return promise.future
  }

  private static func initOrganizationStorageManager(organizationId: String) -> Future<OrganizationStorageManager, StorageError> {
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


  func listUnseenObjects(userId: String, page: Int) -> Future<UnseenObjectsResponse, StorageError> {
    let promise = Promise<UnseenObjectsResponse, StorageError>()

    StorageManager.makeRequest(SizungHttpRouter.UnseenObjects(userId: userId, page: page))
      .onSuccess { (unseenObjectsResponse: UnseenObjectsResponse) in
        let unseenObjects = unseenObjectsResponse.unseenObjects.map { (unseenObject: UnseenObject) -> (UnseenObject) in
          unseenObject.target = unseenObjectsResponse.included.filter { include in
            return include.id == unseenObject.targetId
            }.first

          unseenObject.timeline = unseenObjectsResponse.included.filter { include in
            return include.id == unseenObject.timelineId
            }.first
          return unseenObject
        }

        self.unseenObjects.insertOrUpdate(unseenObjects)
        promise.success(unseenObjectsResponse)
      }.onFailure { error in
        promise.failure(error)
    }
    return promise.future
  }

  func sawTimeLineFor(object: BaseModel) -> Future<[UnseenObject], StorageError> {
    let promise = Promise<[UnseenObject], StorageError>()

    StorageManager.makeRequest(SizungHttpRouter.DeleteUnseenObjects(type: object.type, id: object.id))
      .onSuccess { (unseenObjectsResponse: UnseenObjectsResponse) in
        let diff = Set(self.unseenObjects.collection).subtract(unseenObjectsResponse.unseenObjects)
        self.unseenObjects.replace(Array(diff))
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
