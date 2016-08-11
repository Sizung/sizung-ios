//
//  SizungRouter.swift
//  Sizung
//
//  Created by Markus Klepp on 13/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Alamofire
import ObjectMapper
import SwiftKeychainWrapper

enum SizungHttpRouter: URLRequestConvertible {

  case CheckEmailAvailability(email: String)
  case RegisterUser(user: Sizung.RegisterUser)
  case ConfirmationLink(token: String)
  case Login(email: String, password: String)
  case LoginWithToken(longLivedToken: String)
  case GetLongLivedToken(sessionToken: String)
  case RegisterDevice(token: String)
  case UpdateDevice(deviceId: String, token: String)
  case Logout()
  case Organizations()
  case Organization(id: String)
  case CreateOrganization(name: String)
  case UpdateOrganization(organization: Sizung.Organization)
  case InviteOrganizationMember(email: String, organizationId: String)
  case DeleteOrganizationMember(memberId: String)
  case Conversation(id: String)
  case CreateConversation(conversation: Sizung.Conversation)
  case UpdateConversation(conversation: Sizung.Conversation)
  case AgendaItem(id: String)
  case Deliverable(id: String)
  case ConversationObjects(parent: BaseModel, page: Int)
  case Comments(comment: Comment)
  case UnseenObjectsForUser(userId: String, page: Int)
  case SubscribedUnseenObjectsForOrganization(organizationId: String, page: Int)
  case UnsubscribedUnseenObjectsForOrganization(organizationId: String, page: Int)
  case DeleteUnseenObjects(type: String, id: String)
  case CreateDeliverable(deliverable: Sizung.Deliverable)
  case UpdateDeliverable(deliverable: Sizung.Deliverable)
  case CreateAgendaItem(agendaItem: Sizung.AgendaItem)
  case UpdateAgendaItem(agendaItem: Sizung.AgendaItem)
  case GetUploadAttachmentURL(attachment: Attachment)
  case CreateAttachment(attachment: Attachment)


  var method: Alamofire.Method {
    switch self {
    case .RegisterUser,
         .Login,
         .LoginWithToken,
         .GetLongLivedToken,
         .RegisterDevice,
         .Comments,
         .CreateOrganization,
         .InviteOrganizationMember,
         .CreateConversation,
         .CreateAgendaItem,
         .CreateDeliverable,
         .CreateAttachment:
      return .POST
    case .UpdateDevice,
         .UpdateOrganization,
         .UpdateDeliverable,
         .UpdateAgendaItem,
         .UpdateConversation:
      return .PUT
    case .Logout,
         .DeleteOrganizationMember,
         .DeleteUnseenObjects:
      return .DELETE
    default:
      return .GET
    }
  }

  var path: String {
    switch self {
    case .RegisterUser,
         .CheckEmailAvailability:
      return "/users"
    case .ConfirmationLink:
      return "/users/confirmation"
    case .Login,
         .LoginWithToken,
         .Logout:
      return "/session_tokens"
    case .GetLongLivedToken:
      return "/long_lived_tokens"
    case .RegisterDevice:
      return "/devices"
    case .UpdateDevice(let deviceId, _):
      return "/devices/\(deviceId)"
    case .Organizations,
         .CreateOrganization:
      return "/organizations"
    case .Organization(let id):
      return "/organizations/\(id)"
    case .UpdateOrganization(let organization):
      return "/organizations/\(organization.id)"
    case .InviteOrganizationMember:
      return "/organization_members"
    case .DeleteOrganizationMember(let memberId):
      return "/organization_members/\(memberId)"
    case .Conversation(let id):
      return "/conversations/\(id)"
    case .CreateConversation:
      return "/conversations"
    case .UpdateConversation(let conversation):
      return "/conversations/\(conversation.id)"
    case .AgendaItem(let id):
      return "/agenda_items/\(id)"
    case .CreateAgendaItem:
      return "/agenda_items"
    case .UpdateAgendaItem(let agendaItem):
      return "/agenda_items/\(agendaItem.id)"
    case .Deliverable(let id):
      return "/deliverables/\(id)"
    case .CreateDeliverable:
      return "/deliverables"
    case .UpdateDeliverable(let deliverable):
      return "/deliverables/\(deliverable.id)"
    case .ConversationObjects(let conversation as Sizung.Conversation, _):
      return "/conversations/\(conversation.id)/conversation_objects"
    case .ConversationObjects(let agendaItem as Sizung.AgendaItem, _):
      return "/agenda_items/\(agendaItem.id)/conversation_objects"
    case .ConversationObjects(let deliverable as Sizung.Deliverable, _):
      return "/deliverables/\(deliverable.id)/conversation_objects"
    case .ConversationObjects:
      fatalError("unkown router call to .ConversationObjects")
    case .Comments:
      return "/comments"
    case .UnseenObjectsForUser(let userId, _):
      return "/users/\(userId)/unseen_objects"
    case .UnsubscribedUnseenObjectsForOrganization(let organizationId, _):
      return "/organizations/\(organizationId)/unseen_objects"
    case .SubscribedUnseenObjectsForOrganization(let organizationId, _):
      return "/organizations/\(organizationId)/unseen_objects"
    case .DeleteUnseenObjects(let type, let id):
      return "/\(type)/\(id)/unseen_objects"
    case .GetUploadAttachmentURL(let attachment):
      return "/\(attachment.parentType)/\(attachment.parentId)/attachments/new/"
    case .CreateAttachment(let attachment):
      return "/\(attachment.parentType)/\(attachment.parentId)/attachments"
    }
  }

  var authentication: String? {
    switch self {
    case .RegisterUser,
         .LoginWithToken,
         .Login:
      return nil
    default:
      if let authToken = Configuration.getSessionToken() {
        return "Bearer \(authToken))"
      } else {
        return nil
      }
    }
  }

  var jsonParameters: [String: AnyObject]? {
    switch self {
    case .RegisterUser(let user):
      return [
        "user": [
          "email": user.email!,
          "password": user.password!,
          "password_confirmation": user.passwordConfirmation!,
          "first_name": user.firstname!,
          "last_name": user.lastname!,
          "organization": [
            "name": user.organizationName!
          ]
        ]
      ]
    case .Login(let email, let password):
      return [
        "user": [
          "email": email,
          "password": password
        ]
      ]
    case .LoginWithToken(let longLivedToken):
      return [
        "long_lived_token": longLivedToken
      ]
    case .RegisterDevice(let deviceToken):
      return [
        "device": [
          "token": deviceToken
        ]
      ]
    case .UpdateDevice(_, let deviceToken):
      return [
        "device": [
          "token": deviceToken
        ]
      ]
    case .CreateOrganization(let name):
      return [
        "organization": [
          "name": name
        ]
      ]
    case .UpdateOrganization(let organization):
      return [
        "organization": [
          "id": organization.id,
          "name": organization.name
        ]
      ]
    case .InviteOrganizationMember(let email, let organizationId):
      return [
        "email": email,
        "organization_id": organizationId
      ]
    case .CreateConversation(let conversation):
      let members = conversation.members.map {user in
        return [
          "id": user.id,
          "type": "users"
        ]
      }
      return [
        "conversation": [
          "conversation_members": members,
          "organization_id": conversation.organizationId,
          "title": conversation.title
        ]
      ]

    case .UpdateConversation(let conversation):
      let members = conversation.members.map {user in
        return [
          "member_id": user.id,
          "conversation_id": conversation.id
        ]
      }
      return [
        "conversation": [
          "conversation_members": members,
          "organization_id": conversation.organizationId,
          "title": conversation.title
        ]
      ]
    case .Comments(let comment):
      let commentableType = String(comment.commentable.type.capitalizedString.characters.dropLast()).stringByReplacingOccurrencesOfString("_", withString: "")
      return [
        "comment": [
          "commentable_id": comment.commentable.id,
          "commentable_type": commentableType,
          "body": comment.body
        ]
      ]
    case .CreateDeliverable(let deliverable):
      var deliverableJSON: Dictionary<String, AnyObject> = [
        "assignee_id": deliverable.assigneeId,
        "title": deliverable.title
      ]

      switch deliverable {
      case let agendaItemDeliverable as AgendaItemDeliverable:
        deliverableJSON["parent_id"] = agendaItemDeliverable.agendaItemId
        deliverableJSON["parent_type"] = "AgendaItem"
      default:
        deliverableJSON["parent_id"] = deliverable.parentId
        deliverableJSON["parent_type"] = "Conversation"
      }

      let dateString = ISODateTransform().transformToJSON(deliverable.dueOn)
      deliverableJSON["due_on"] = dateString

      return [
        "deliverable": deliverableJSON
      ]

    case .UpdateDeliverable(let deliverable):

      var deliverableJSON: Dictionary<String, AnyObject> = [
        "title": deliverable.title,
        "assignee_id": deliverable.assigneeId,
        "status": deliverable.status,
        "archived": deliverable.archived == true
      ]

      let dateString = ISODateTransform().transformToJSON(deliverable.dueOn)
      deliverableJSON["due_on"] = dateString

      return [
        "deliverable": deliverableJSON
      ]
    case .CreateAgendaItem(let agendaItem):
      return [
        "agenda_item": [
          "conversation_id": agendaItem.conversationId,
          "title": agendaItem.title,
          "owner_id": agendaItem.ownerId
        ]
      ]
    case .UpdateAgendaItem(let agendaItem):

      let agendaItemJSON: Dictionary<String, AnyObject> = [
        "title": agendaItem.title,
        "owner_id": agendaItem.ownerId,
        "status": agendaItem.status,
        "archived": agendaItem.archived == true
      ]

      return [
        "agenda_item": agendaItemJSON
      ]

    case .CreateAttachment(let attachment):
      return [
        "attachment": [
          "file_name": attachment.fileName,
          "file_size": attachment.fileSize,
          "file_type": attachment.fileType,
          "persistent_file_id": attachment.fileUrl
        ]
      ]

    default:
      return nil
    }
  }

  var urlParams: [String: AnyObject]? {
    switch self {
    case .CheckEmailAvailability(let email):
      return [
        "email": email
      ]
    case .ConfirmationLink(let token):
      return [
        "confirmation_token": token
      ]
    case .ConversationObjects(_, let page):
      return [
        "page[number]": page,
        "page[size]": 20
      ]
    case .UnseenObjectsForUser(_, let page):
      return [
        "page[number]": page,
        "page[size]": 1000
      ]
    case .SubscribedUnseenObjectsForOrganization(_, let page):
      return [
        "include": "target,timeline",
        "page[number]": page,
        "page[size]": 100,
        "filter": "subscribed"
      ]
    case .UnsubscribedUnseenObjectsForOrganization(_, let page):
      return [
        "include": "target,timeline",
        "page[number]": page,
        "page[size]": 500,
        "filter": "unsubscribed"
      ]

    case .GetUploadAttachmentURL(let attachment):
      return [
        "objectName": attachment.fileName,
        "contentType": attachment.fileType
      ]

    default:
      return nil
    }
  }

  // MARK: URLRequestConvertible

  var URLRequest: NSMutableURLRequest {

    let URL = NSURL(string: Configuration.APIEndpoint())!
    let mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(path))
    mutableURLRequest.HTTPMethod = method.rawValue
    mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    mutableURLRequest.setValue(Configuration.getDeviceId(), forHTTPHeaderField: "X-DEVICE")

    mutableURLRequest.setValue(self.authentication, forHTTPHeaderField: "Authorization")

    switch self {
    case .RegisterUser,
         .Login,
         .LoginWithToken,
         .RegisterDevice,
         .UpdateDevice,
         .CreateOrganization,
         .UpdateOrganization,
         .InviteOrganizationMember,
         .CreateDeliverable,
         .UpdateDeliverable,
         .CreateAgendaItem,
         .UpdateAgendaItem,
         .CreateConversation,
         .UpdateConversation,
         .Comments,
         .CreateAttachment:
      return Alamofire.ParameterEncoding.JSON.encode(
        mutableURLRequest,
        parameters: self.jsonParameters
        ).0
    case .CheckEmailAvailability,
         .ConfirmationLink,
         .ConversationObjects,
         .UnseenObjectsForUser,
         .SubscribedUnseenObjectsForOrganization,
         .UnsubscribedUnseenObjectsForOrganization,
         .GetUploadAttachmentURL:
      return Alamofire.ParameterEncoding.URL.encode(
        mutableURLRequest,
        parameters: self.urlParams
        ).0
    default:
      return mutableURLRequest
    }
  }
}
