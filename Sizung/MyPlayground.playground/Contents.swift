//: Playground - noun: a place where people can play

import UIKit

let currentDate = NSDate

let unsortedArray = [1,3,4,2]

unsortedArray.sort { left, right in
  return left.comp
}