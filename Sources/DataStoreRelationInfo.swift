//
//  DataStoreRelationInfo.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 14/03/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation

/// A description of the relationships of a record.
public protocol DataStoreRelationInfo: DataStorePropertyInfo {

    /// The Table description of the receiver's destination.
    var destinationTable: DataStoreTableInfo? { get }
    /// The relationship that represents the inverse of the receiver.
    var inverseRelationship: DataStoreRelationInfo? { get }
    /// The maximum count of the receiver.
    var maxCount: Int { get }
    /// The minimum count of the receiver.
    var minCount: Int { get }
    /// The delete rule of the receiver.
    var deleteRule: DeleteRule { get }
    /// A Boolean value that indicates whether the receiver represents a to-many relationship.
    var isToMany: Bool { get }
    /// Returns a Boolean value that indicates whether the receiver describes an ordered relationship.
    var isOrdered: Bool { get }
    /// Returns a Boolean value that indicates whether the relation is optional and can be persisted with nil.
    var isOptional: Bool {get}

}

/// Rule used when deleting record
public enum DeleteRule: UInt {
    /// If the object is deleted, no modifications are made to objects at the destination of the relationship.
    case noAction
    /// If the object is deleted, back pointers from the objects to which it is related are nullified.
    case nullify
    /// If the object is deleted, the destination object or objects of this relationship are also deleted.
    case cascade
    /// If the destination of this relationship is not nil, the delete creates a validation error.
    case deny
}
