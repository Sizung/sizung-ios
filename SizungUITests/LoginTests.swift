//
//  LoginUITests.swift
//  Sizung
//
//  Created by Markus Klepp on 06/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import XCTest
import Nimble
import OHHTTPStubs
@testable import Pods_Sizung

class LoginUITests: XCTestCase {

  let app = XCUIApplication()

  override func setUp() {
    super.setUp()

    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    app.launch()

    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()

    OHHTTPStubs.removeAllStubs()
  }

  func testSuccessfulLoginFlow() {
    let mailTextField = app.textFields["email"]
    let passwordTextField = app.textFields["password"]
    let loginButton = app.buttons["Login"]

    expect(UITestHelper.hasFocus(mailTextField)).to(beTrue())

    app.typeText("test@example.com")

    let mailTextFieldValue = mailTextField.value as! String
    expect(mailTextFieldValue) == "test@example.com"

    app.typeText(XCUIKeyboardKeyReturn)


    expect(UITestHelper.hasFocus(passwordTextField)).to(beTrue())

    passwordTextField.typeText("asdf")

//  mock http request
//    stub(isHost("*")) { _ in
//      let obj = ["key1":"value1", "key2":["value2A","value2B"]]
//      return OHHTTPStubsResponse(JSONObject: obj, statusCode: 200, headers: nil)
//    }

    loginButton.tap()

    // Login Screen should no longer be visible
//    expect(app.contr)

  }



//  func testEmptyUsernameLogin() {
//    app.buttons["Login"].tap()
//
//    app.alerts["Error"].buttons["Ok"].tap()
//  }

}
