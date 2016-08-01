//
//  SignupViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 01/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import Alamofire
import JVFloatLabeledTextField
import MRProgress

struct RegisterUser {
  var email: String?
  var password: String?
  var passwordConfirmation: String?
  var firstname: String?
  var lastname: String?
  var organizationName: String?
}

protocol SignupViewControllerDelegate {
  var responderChain: [UIResponder] { get }
  var nextViewController: SignupViewController? { get }
}

class SignupViewController: UIViewController, SignupViewControllerDelegate, UITextFieldDelegate {

  var registerUser = RegisterUser()

  var responderChain: [UIResponder] { return [] }
  var nextViewController: SignupViewController? { return nil }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.responderChain.first!.becomeFirstResponder()
  }

  func textFieldShouldReturn(textField: UITextField) -> Bool {

    if let index = self.responderChain.indexOf(textField) {
      if index < responderChain.count {
        self.responderChain[index+1].becomeFirstResponder()
      } else {
        self.validateAndNext()
      }
    }

    return true
  }

  @IBAction func validateAndNext() {
    fatalError()
  }

  @IBAction func back() {
    self.navigationController?.popViewControllerAnimated(true)
  }

  func showNext() {
    let nextViewController = self.nextViewController!
    nextViewController.registerUser = self.registerUser

    self.navigationController?.pushViewController(nextViewController, animated: true)
  }

  func showAlertForTextField(textField: UITextField, text: String) {
    textField.becomeFirstResponder()

    self.showAlert(text)
  }

  func showAlert(text: String) {
    let alert = UIAlertController(
      title: "Error",
      message: text,
      preferredStyle: UIAlertControllerStyle.Alert
    )

    let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)

    alert.addAction(defaultAction)

    presentViewController(alert, animated: true, completion: nil)
  }
}

class SignupCredentialsViewController: SignupViewController {

  @IBOutlet weak var emailTextField: JVFloatLabeledTextField!
  @IBOutlet weak var passwordTextField: JVFloatLabeledTextField!
  @IBOutlet weak var passwordConfirmationTextField: JVFloatLabeledTextField!

  override var responderChain: [UIResponder] {
    return [emailTextField, passwordTextField, passwordConfirmationTextField]
  }

  override var nextViewController: SignupViewController? {
    get {
      return R.storyboard.login.signupProfileViewController()
    }
  }

  @IBAction func close(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }

  @IBAction override func validateAndNext() {
    let email = emailTextField.text
    let password = passwordTextField.text
    let passwordConfirmation = passwordConfirmationTextField.text

    if email?.characters.count < 2 || email!.containsString("@") == false {
      showAlertForTextField(emailTextField, text: "Please enter valid email")
      return
    }

    if password?.characters.count < 8 {
      showAlertForTextField(passwordTextField, text: "The minimal length for passwords is 8 characters")
      return
    }

    if password != passwordConfirmation {
      showAlertForTextField(passwordConfirmationTextField, text: "Passwords do not match")
      return
    }

    MRProgressOverlayView.showOverlayAddedTo(self.view, animated: true)

    Alamofire.request(SizungHttpRouter.CheckEmailAvailability(email: email!))
      .validate()
      .responseJSON { response in
        switch response.result {
        case .Success(let JSON)
          where JSON.objectForKey("emailExists") is Bool:

          let emailExists = JSON["emailExists"] as? Bool

          if emailExists! {
            self.showAlertForTextField(self.emailTextField, text: "Email already exists")
          } else {
            self.registerUser.email = email
            self.registerUser.password = password
            self.registerUser.passwordConfirmation = passwordConfirmation

            self.showNext()
          }
        default:
          self.showAlert("Please try again")
        }

        MRProgressOverlayView.dismissOverlayForView(self.view, animated: true)
    }
  }
}

class SignupProfileViewController: SignupViewController {

  var email: String?
  var password: String?
  var passwordConfirmation: String?

  @IBOutlet weak var firstnameTextField: JVFloatLabeledTextField!
  @IBOutlet weak var lastnameTextField: JVFloatLabeledTextField!

  override var responderChain: [UIResponder] {
    return [firstnameTextField, lastnameTextField]
  }

  override var nextViewController: SignupViewController? {
    get {
      return R.storyboard.login.signupOrganizationViewController()
    }
  }

  @IBAction override func validateAndNext() {
    let firstname = firstnameTextField.text
    let lastname = lastnameTextField.text

    if firstname?.characters.count < 1 {
      showAlertForTextField(firstnameTextField, text: "Please enter a name")
      return
    }

    if lastname?.characters.count < 1 {
      showAlertForTextField(lastnameTextField, text: "Please enter a name")
      return
    }

    self.registerUser.firstname = firstname
    self.registerUser.lastname = lastname

    self.showNext()
  }
}

class SignupOrganizationViewController: SignupViewController {

  @IBOutlet weak var organizationTextField: JVFloatLabeledTextField!

  override var responderChain: [UIResponder] {
    return [organizationTextField]
  }

  override var nextViewController: SignupViewController? {
    get {
      return nil
    }
  }

  @IBAction override func validateAndNext() {
    let organizationName = organizationTextField.text

    if organizationName?.characters.count < 1 {
      showAlertForTextField(organizationTextField, text: "Please enter a name for your organization")
      return
    }


    self.registerUser.organizationName = organizationName

    MRProgressOverlayView.showOverlayAddedTo(self.view, animated: true)

    // submit to server
    Alamofire.request(SizungHttpRouter.RegisterUser(user: self.registerUser))
      .validate()
      .responseJSON { response in
        switch response.result {
        case .Success:
          self.showSuccess()
        default:
          self.showAlert("Please try again")
        }

        MRProgressOverlayView.dismissOverlayForView(self.view, animated: true)

    }
  }

  func showSuccess() {
    let alert = UIAlertController(
      title: "Success",
      message: "Please check your email for confirmation link",
      preferredStyle: .Alert
    )

    let defaultAction = UIAlertAction(title: "OK", style: .Default) { _ in
      self.dismissViewControllerAnimated(true, completion: nil)
    }

    alert.addAction(defaultAction)

    presentViewController(alert, animated: true, completion: nil)
  }
}
