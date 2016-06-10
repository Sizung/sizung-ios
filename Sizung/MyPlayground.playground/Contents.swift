//: Playground - noun: a place where people can play

import UIKit

let formatter = NSDateFormatter()
formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

let dateString = "2016-05-04T12:23:46.504Z"


formatter.dateFromString(dateString)
