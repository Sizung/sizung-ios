//
//  UITestHelper.swift
//  Sizung
//
//  Created by Markus Klepp on 06/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import XCTest

public class UITestHelper {
    static func hasFocus(textField: XCUIElement) -> Bool {
        let hasFocus = (textField.valueForKey("hasKeyboardFocus") as? Bool) ?? false
        return hasFocus
    }
}
