//
//  OrganizationStorageManager.swift
//  Sizung
//
//  Created by Markus Klepp on 08/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ReactiveKit
import BrightFutures
import Alamofire

class OrganizationStorageManager {

  let organization: Organization!

  init(organization: Organization) {
    self.organization = organization
  }

  let conversations: CollectionProperty <[Conversation]> = CollectionProperty([])
  let agendaItems: CollectionProperty <[AgendaItem]> = CollectionProperty([])
  let deliverables: CollectionProperty <[Deliverable]> = CollectionProperty([])
  let unseenObjects: CollectionProperty <[UnseenObject]> = CollectionProperty([])

  let users: CollectionProperty <[User]> = CollectionProperty([])

  func getObject(withId itemId: String, type: String) -> BaseModel? {
    switch type {
    case "conversations":
      return self.conversations[itemId]

    case "agenda_items":
      return self.agendaItems[itemId]
    case "deliverables":
      return self.deliverables[itemId]
    case "users":
      return self.users[itemId]
    default:
      fatalError()
    }
  }

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

  func createConversation(conversation: Conversation) -> Future<Conversation, StorageError> {
    let promise = Promise<Conversation, StorageError>()

    StorageManager.makeRequest(SizungHttpRouter.CreateConversation(conversation: conversation))
      .onSuccess { (conversationResponse: ConversationResponse) in

        let conversation = conversationResponse.conversation
        self.conversations.insertOrUpdate([conversation])
        promise.success(conversation)

      }.onFailure { error in
        promise.failure(error)
    }

    return promise.future
  }

  func updateConversation(conversation: Conversation) -> Future<Conversation, StorageError> {
    let promise = Promise<Conversation, StorageError>()

    StorageManager.makeRequest(SizungHttpRouter.UpdateConversation(conversation: conversation))
      .onSuccess { (conversationResponse: ConversationResponse) in

        let conversation = conversationResponse.conversation
        self.conversations.insertOrUpdate([conversation])
        promise.success(conversation)

      }.onFailure { error in
        promise.failure(error)
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

  func createDeliverable(deliverable: Deliverable) -> Future<Deliverable, StorageError> {
    let promise = Promise<Deliverable, StorageError>()
    StorageManager.makeRequest(SizungHttpRouter.CreateDeliverable(deliverable: deliverable))
      .onSuccess { (deliverableResponse: DeliverableResponse) in
        self.deliverables.append(deliverableResponse.deliverable)
        promise.success(deliverableResponse.deliverable)
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

  func createAgendaItem(agendaItem: AgendaItem) -> Future<AgendaItem, StorageError> {
    let promise = Promise<AgendaItem, StorageError>()
    StorageManager.makeRequest(SizungHttpRouter.CreateAgendaItem(agendaItem: agendaItem))
      .onSuccess { ( agendaItemResponse: AgendaItemResponse ) in
        self.agendaItems.append(agendaItemResponse.agendaItem)
        promise.success(agendaItemResponse.agendaItem)
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

  func uploadAttachment(attachment: Attachment, data: NSData, progress: (Float)->()) -> Future<Attachment, StorageError> {
    let promise = Promise<Attachment, StorageError>()

    StorageManager.makeRequest(SizungHttpRouter.GetUploadAttachmentURL(attachment: attachment))
      .onSuccess { ( getAttachmentUploadResponse: GetAttachmentUploadResponse) in

        attachment.fileUrl = getAttachmentUploadResponse.signedUrl

        let url = NSURL(string: attachment.fileUrl)!

        let headers: [String: String] = [
          "Content-Type": attachment.fileType,
          "x-amz-acl": "private"
        ]

        // use alamofire direct for s3 upload
        Alamofire.upload(.PUT, url, headers: headers, data: data)
          .validate()
          .progress { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
            let progressVal = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
            progress(progressVal)
          }
          .responseData(queue: StorageManager.networkQueue) { response in
            switch response.result {
            case .Success:
              StorageManager.makeRequest(SizungHttpRouter.CreateAttachment(attachment: attachment))
                .onSuccess { (attachmentResponse: AttachmentResponse) in
                  promise.success(attachmentResponse.attachment)
                }.onFailure { error in
                  promise.failure(error)
              }
            case .Failure(let error):
              Error.log(error)
              promise.failure(.Other)
            }
        }
      }.onFailure { error in
        promise.failure(error)
    }
    return promise.future
  }

  func listUnseenObjectsForOrganization(orgId: String, page: Int) -> Future<UnseenObjectsResponse, StorageError> {
    let promise = Promise<UnseenObjectsResponse, StorageError>()

    StorageManager.makeRequest(SizungHttpRouter.UnseenObjectsForOrganization(organizationId: orgId, page: page))
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

        promise.success(unseenObjectsResponse)
        self.unseenObjects.insertOrUpdate(unseenObjects)
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
}
