//
//  CreateAgendaItemViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 18/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class CreateAgendaItemViewController: UIViewController, UITextFieldDelegate {

  var agendaItem: AgendaItem?
  var conversation: Conversation?
  var agendaItemCreateDelegate: AgendaItemCreateDelegate?
  var storageManager: OrganizationStorageManager?

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var agendaItemNameTextField: UITextField!
  override func viewDidLoad() {
    super.viewDidLoad()

    if agendaItem == nil {
      agendaItem = AgendaItem(conversationId: conversation!.id)
    }

    StorageManager.storageForSelectedOrganization()
      .onSuccess { storageManager in
        self.storageManager = storageManager
    }

    if let title = agendaItem?.title {
      self.titleLabel.text = "Edit '\(title)'"
    }

    agendaItemNameTextField.text = self.agendaItem?.title
    agendaItemNameTextField.becomeFirstResponder()
    agendaItemNameTextField.delegate = self
  }


  @IBAction func close(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }

  @IBAction func save(sender: UIButton?) {

    agendaItem!.title = agendaItemNameTextField.text

    guard agendaItem!.title.characters.count > 0 else {
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
    if agendaItem!.new {
      storageManager?.createAgendaItem(agendaItem!).onSuccess(callback: successFunc).onFailure(callback: errorFunc)
    } else {
      storageManager?.updateAgendaItem(agendaItem!).onSuccess(callback: successFunc).onFailure(callback: errorFunc)
    }
  }

  func textFieldShouldReturn(textField: UITextField) -> Bool {
    self.save(nil)
    return true
  }
}

protocol AgendaItemCreateDelegate {
  func agendaItemCreated(agendaItem: AgendaItem)
}
