//
//  LoginViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 05/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import Alamofire

public class LoginViewController: UIViewController, UITextFieldDelegate {
  
  @IBOutlet weak var emailTextField: UITextField!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  
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
    
    
    UIView.animateWithDuration(0.5,
                               animations: {
                                self.loginButton.alpha = 0
    })
    self.activityIndicator.startAnimating()
    
    Alamofire.request(Router.Login(email: email!, password: password!))
      .validate()
      .responseJSON { response in
        switch response.result {
        case .Success(let JSON)
          where JSON.objectForKey("token") != nil:
          
          let token = JSON.objectForKey("token")!
          
          let keychainWrapper = KeychainWrapper()
          keychainWrapper.mySetObject(token, forKey:kSecValueData)
          keychainWrapper.writeToKeychain()
          
          self.performSegueWithIdentifier("dismissLogin", sender: self)
        case .Failure
          where response.response?.statusCode == 401:
          self.showAlert("username/password")
        default:
          print(response.response)
          self.showAlert("Something went wrong")
        }
        
        self.activityIndicator.stopAnimating()
        UIView.animateWithDuration(0.5,
          animations: {
            self.loginButton.alpha = 1
        })
    }
    
  }
  
  func showAlertForTextField(textField: UITextField, text: String) {
    textField.becomeFirstResponder()
    
    self.showAlert(text)
  }
  
  func showAlert(text: String) {
    let alert = UIAlertController(title: "Error", message: text, preferredStyle: UIAlertControllerStyle.Alert)
    
    let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
    
    alert.addAction(defaultAction)
    
    presentViewController(alert, animated: true, completion: nil)
  }
  
  override public func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    emailTextField.becomeFirstResponder()
  }
  
  public func textFieldShouldReturn(textField: UITextField) -> Bool {
    
    if (textField == self.emailTextField) {
      self.passwordTextField.becomeFirstResponder()
    }
    
    return true
  }
}

