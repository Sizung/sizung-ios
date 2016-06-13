//
//  CollectionPropertyExtension.swift
//  Sizung
//
//  Created by Markus Klepp on 08/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import ReactiveKit

extension CollectionPropertyType where Collection == Array<Member>, Member : Equatable, Member : Hashable {
  public func insertOrUpdate(newCollection: [Self.Member]){
    var inserts: [Int] = []
    var updates: [Int] = []
    
    inserts.reserveCapacity(newCollection.count)
    updates.reserveCapacity(collection.count)
    
    let newSet = Set(newCollection)
    let currentSet = Set(collection)
    
    let newElements = newSet.subtract(currentSet)
    let updatedElements = newSet.intersect(currentSet)
    
    let updatedCollection = self.collection + newElements
    
    for newElement in newElements {
      inserts.append(updatedCollection.indexOf(newElement)!)
    }
    
    for updatedElement in updatedElements {
      updates.append(collection.indexOf(updatedElement)!)
    }
    
    update(CollectionChangeset(collection: updatedCollection, inserts: inserts, deletes: [], updates: updates))
  }
}