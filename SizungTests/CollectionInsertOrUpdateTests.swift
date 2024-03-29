//
//  CollectionTests.swift
//  Sizung
//
//  Created by Markus Klepp on 07/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import XCTest
import Nimble
import ReactiveKit
import Pods_Sizung

class TestModel: Hashable, CustomDebugStringConvertible {
  let id: String
  let payload: String

  init(id: String, payload: String) {
    self.id = id
    self.payload = payload
  }

  var hashValue: Int {
    return id.hashValue
  }

  var description: String {
    return "id: \(id)"
  }

  var debugDescription: String {
    return self.description
  }
}

func ==(lhs: TestModel, rhs: TestModel) -> Bool {
  return lhs.id == rhs.id
}

class CollectionInsertOrUpdateTests: XCTestCase {

  struct TestCase {
    let array1: CollectionProperty <[TestModel]>
    let array2: [TestModel]

    let expectedArray: CollectionProperty <[TestModel]>

    init(_ a: [TestModel], _ b: [TestModel], _ expectedArray: [TestModel]) {
      self.array1 = CollectionProperty(a)
      self.array2 = b
      self.expectedArray = CollectionProperty(expectedArray)
    }
  }

  func testReplace() {
    let model1 = TestModel(id: "1", payload: "payload1")
    let model2 = TestModel(id: "2", payload: "payload2")

    let tests: [TestCase] = [
      TestCase([], [model1], [model1]),
      TestCase([model1], [model2], [model2])
    ]

    for test in tests {

      test.array1.replace(test.array2, performDiff: true)

      expect(test.array1.collection).to(contain(test.expectedArray.collection))
    }
  }

  func testInsertOrUpdate() {

    let model1 = TestModel(id: "1", payload: "payload1")
    let model2 = TestModel(id: "2", payload: "payload2")
    let model3 = TestModel(id: "3", payload: "payload3")

    let modifiedModel1 = TestModel(id: "1", payload: "payload1_new")

    let tests: [TestCase] = [
      TestCase([model1], [], [model1]),
      TestCase([model1, model2], [model3], [model1, model2, model3]),
      TestCase([model1, model2], [modifiedModel1], [modifiedModel1, model2]),
      ]

    for test in tests {

      test.array1.insertOrUpdate(test.array2)

      expect(Set(test.array1.collection)).to(equal(Set(test.expectedArray.collection)))
    }

  }
}
