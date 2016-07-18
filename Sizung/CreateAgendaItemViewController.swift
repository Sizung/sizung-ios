//
//  CreateAgendaItemViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 18/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class CreateAgendaItemViewController: UIViewController, UITextFieldDelegate {

  var conversation: Conversation?
  var agendaItemCreateDelegate: AgendaItemCreateDelegate?
  var storageManager: OrganizationStorageManager?

  @IBOutlet weak var agendaItemNameTextField: UITextField!
  override func viewDidLoad() {
    super.viewDidLoad()

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.storageManager = storageManager
    }

    agendaItemNameTextField.becomeFirstResponder()
    agendaItemNameTextField.delegate = self
  }


  @IBAction func close(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }

  @IBAction func save(sender: UIButton?) {

    let agendaItem = AgendaItem(conversationId: conversation!.id)

    agendaItem.title = agendaItemNameTextField.text

    guard agendaItem.title.characters.count > 0 else {
      InAppMessage.showErrorMessage("Please enter a title")
      agendaItemNameTextField.becomeFirstResponder()
      return
    }

    sender?.enabled = false

    func successFunc(createdAgendaitem: AgendaItem) {
      self.dismissViewControllerAnimated(true) {
        self.agendaItemCreateDelegate?.agendaItemCreated(createdAgendaitem)
      }
    }

    func errorFunc(error: StorageError) {
      InAppMessage.showErrorMessage("There has been an error saving your Agenda - Please try again")
      sender?.enabled = true
    }

    // save agenda
    storageManager?.createAgendaItem(agendaItem).onSuccess(callback: successFunc).onFailure(callback: errorFunc)
  }

  func textFieldShouldReturn(textField: UITextField) -> Bool {
    self.save(nil)
    return true
  }
}

protocol AgendaItemCreateDelegate {
  func agendaItemCreated(agendaItem: AgendaItem)
}
