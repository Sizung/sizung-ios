//
//  LoginViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 05/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import Alamofire
import MRProgress

public class LoginViewController: UIViewController, UITextFieldDelegate {

  @IBOutlet weak var emailTextField: UITextField!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var logoutButton: UIButton!

  var loginDelegate: LoginDelegate?
  var email: String?

  override public func viewDidLoad() {
    super.viewDidLoad()

    if email != nil {
      logoutButton.hidden = false
      emailTextField.enabled = false
      emailTextField.text = email
    }
  }

  @IBAction func login(sender: AnyObject) {
    let email = emailTextField.text
    let password = passwordTextField.text

    if email?.characters.count < 2 || email!.containsString("@") == false {
      showAlertForTextField(emailTextField, text: "Please enter valid email")
      return
    }

    if password!.isEmpty {
      showAlertForTextField(passwordTextField, text: "Please enter a password")
      return
    }

    MRProgressOverlayView.showOverlayAddedTo(self.view, animated: true)

    Alamofire.request(SizungHttpRouter.Login(email: email!, password: password!))
      .validate()
      .responseJSON { response in
        switch response.result {
        case .Success(let JSON)
          where JSON.objectForKey("token") is String:

          let token = AuthToken(data: JSON["token"] as? String)

          token.validateAndStore()
            .onSuccess() { _ in
              Configuration.setLoginEmail(email!)
              self.loginDelegate?.loginSuccess(self)
            }.onFailure() { error in
              let message = "login error: \(error)"
              Error.log(message)
              self.showAlert("Something went wrong. Please try again")
          }

        case .Failure
          where response.response?.statusCode == 401:
          self.showAlert("username/password")
        default:
          let message = "login error: \(response.response)"
          Error.log(message)
          self.showAlert("Something went wrong")
        }

        MRProgressOverlayView.dismissOverlayForView(self.view, animated: true)
    }

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

  override public func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

    emailTextField.becomeFirstResponder()
  }

  public func textFieldShouldReturn(textField: UITextField) -> Bool {

    if textField == self.emailTextField {
      self.passwordTextField.becomeFirstResponder()
    } else if textField == self.passwordTextField {
      self.login(textField)
    }

    return true
  }

  @IBAction func logout(sender: AnyObject) {
    Configuration.reset()
    StorageManager.sharedInstance.reset()

    logoutButton.hidden = true
    emailTextField.enabled = true
    emailTextField.text = ""
  }
}

protocol LoginDelegate {
  func loginSuccess(loginViewController: LoginViewController)
}
