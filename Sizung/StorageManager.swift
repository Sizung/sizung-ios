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
import Bond

class StorageManager {
  //  singleton
  static let sharedInstance = StorageManager()
  private init() {}
  
  var isInitialized = false
  var isLoading = false
  var organizations: ObservableArray<Organization> = []
  
  func updateOrganizations() {
    
    self.isLoading = true
    Alamofire.request(Router.Organizations())
      .validate()
      .responseJSON { response in
        switch response.result {
        case .Success(let JSON):
          if let organizationResponse = Mapper<OrganizationsResponse>().map(JSON) {
            self.organizations.diffInPlace(organizationResponse.data)
          }
        case .Failure
          where response.response?.statusCode == 401:
          NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
        default:
          print(response.response)
        }
        self.isLoading = false
    }
  }
  
  
  func getOrganization(id: String) -> Organization? {
    return organizations.filter { (organization) -> Bool in
      organization.id == id
      }.first
  }
}