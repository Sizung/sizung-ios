//
//  AccountViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 31/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class AccountViewController: UIViewController {
  
  @IBOutlet weak var versionLabel: UILabel!
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.versionLabel.text = version()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @IBAction func logoutClicked(sender: AnyObject) {
    KeychainWrapper.removeObjectForKey(Configuration.Settings.AUTH_TOKEN)
    KeychainWrapper.removeObjectForKey(Configuration.Settings.SELECTED_ORGANIZATION)
    StorageManager.sharedInstance.reset()
    
    NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Settings.NOTIFICATION_KEY_AUTH_ERROR, object: nil)
  }
  
  @IBAction func close(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  func version() -> String {
    let dictionary = NSBundle.mainBundle().infoDictionary!
    let version = dictionary["CFBundleShortVersionString"] as! String
    let build = dictionary["CFBundleVersion"] as! String
    return "v\(version) - build #\(build)"
  }
}
