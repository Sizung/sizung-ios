//
//  OrganizationViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 01/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import KCFloatingActionButton

class OrganizationViewController: UIViewController, OrganizationTableViewDelegate, ConversationTableViewDelegate {

  @IBOutlet weak var titleButton: UIButton!
  @IBOutlet weak var searchBar: UITextField!
  @IBOutlet weak var closeButton: SizungButton!

  var storageManager: OrganizationStorageManager?

  var navController: UINavigationController?

  var organizationsViewController: OrganizationsViewController?
  var conversationListViewController: ConversationsViewController?

  // used for initial loading of conversation
  var conversationViewController: UIViewController?

  @IBOutlet weak var closeButtonHiddenConstraint: NSLayoutConstraint!

  override func viewDidLoad() {
    super.viewDidLoad()

    UIApplication.sharedApplication().statusBarStyle = .Default

    searchBar.attributedPlaceholder = NSAttributedString(string: searchBar.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])

    UIApplication.sharedApplication().statusBarStyle = .LightContent

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in

        self.storageManager = storageManager

        // load conversation
        if let conversationViewController = self.conversationViewController {
          self.showViewController(conversationViewController, sender: nil)
          self.conversationViewController = nil
        }
        self.titleButton.setTitle(storageManager.organization.name, forState: .Normal)
    }
  }

  func calculateUnseenConversations() -> Int {
    var unseenConversationSet = Set<String>()
    self.storageManager!.unseenObjects.collection.filter { unseenObject in
        return unseenObject.organizationId == Configuration.getSelectedOrganization()
      }.forEach { unseenObject in
      if let conversationId = unseenObject.conversationId {
        unseenConversationSet.insert(conversationId)
      }
    }
    return unseenConversationSet.count
  }

  @IBAction func showOrganizations(sender: AnyObject) {
    organizationsViewController = R.storyboard.organizations.initialViewController()
    organizationsViewController?.organizationTableViewDelegate = self
    self.showViewController(organizationsViewController!, sender: self)
  }

  @IBAction func hideOrganizations(sender: AnyObject) {
    organizationsViewController?.dismissViewControllerAnimated(true, completion: nil)
    organizationsViewController = nil
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if R.segue.organizationViewController.embedNav(segue: segue) != nil {
      if let navController = segue.destinationViewController as? UINavigationController {
        self.navController = navController
      } else {
        fatalError()
      }
    } else {
      fatalError()
    }
  }

  func organizationSelected(organization: Organization) {
    if organization.id != Configuration.getSelectedOrganization() {
      // dismiss organizationsviewcontroller
      self.dismissViewControllerAnimated(false) {
        // dismiss self
        self.dismissViewControllerAnimated(true) {
          if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            appDelegate.switchToOrganization(organization.id)
          }
        }
      }
    } else {
      self.hideOrganizations(self)
    }
  }

  @IBAction func closeButtonTouched(sender: AnyObject) {
    self.hideCloseButton()

    if self.conversationListViewController != nil {
      hideConversations()
    }

    let transition = CATransition()
    transition.duration = 0.3
    transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    transition.type = kCATransitionFade
    self.navController?.view.layer.addAnimation(transition, forKey: nil)

    self.navController?.popToRootViewControllerAnimated(false)
  }

  func showCloseButton() {
    closeButton.hidden = false
    closeButton.alpha = 0
    UIView.animateWithDuration(0.2) {self.closeButton.alpha = 1}

    closeButtonHiddenConstraint.priority = UILayoutPriorityDefaultHigh-1

    self.animateSearchBarWidthChange()
  }

  func hideCloseButton() {
    UIView.animateWithDuration(0.2, animations: {
      self.closeButton.alpha = 0
      }, completion: { _ in
        self.closeButton.hidden = true
    })

    closeButtonHiddenConstraint.priority = UILayoutPriorityDefaultHigh+1

    self.animateSearchBarWidthChange()
  }

    func animateSearchBarWidthChange() {
      UIView.animateWithDuration(0.2) {
        self.searchBar.layoutIfNeeded()
      }
    }

  func showConversations() {

    self.showCloseButton()

    let transition = CATransition()
    transition.duration = 0.3
    transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    transition.type = kCATransitionFade
    self.navController?.view.layer.addAnimation(transition, forKey: nil)

    conversationListViewController = R.storyboard.conversations.initialViewController()
    conversationListViewController?.conversationTableViewDelegate = self
    self.navController?.pushViewController(conversationListViewController!, animated: false)
  }

  func hideConversations() {
    self.searchBar.resignFirstResponder()
    self.searchBar.text = ""

    self.hideCloseButton()

    let transition = CATransition()
    transition.duration = 0.3
    transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    transition.type = kCATransitionFade
    self.navController?.view.layer.addAnimation(transition, forKey: nil)

    self.navController?.popViewControllerAnimated(false)
    conversationListViewController = nil
  }

  func conversationSelected(conversation: Conversation) {
    self.showConversation(conversation)
  }

  func showConversation(conversation: Conversation) {
    let conversationViewController = R.storyboard.conversation.initialViewController()!
    conversationViewController.conversation = conversation
    conversationViewController.modalTransitionStyle = .CrossDissolve

    self.hideConversations()
    self.presentViewController(conversationViewController, animated: true, completion: nil)
  }
}

extension OrganizationViewController: UITextFieldDelegate {

  func textFieldDidBeginEditing(textField: UITextField) {
    self.showConversations()
  }

  func textFieldDidEndEditing(textField: UITextField) {
    self.hideConversations()
  }

  @IBAction func textFieldDidChange(sender: UITextField) {
    let text = sender.text ?? ""
    self.conversationListViewController?.filterFor(text)
  }
}
