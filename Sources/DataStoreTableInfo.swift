//
//  DataStoreTable.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 24/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

public protocol DataStoreTableInfo {
    var name: String {get}
    var localizedName: String {get}
    var isAbstract: Bool {get}
    var fields: [DataStoreFieldInfo] {get}
    var fieldsByName: [String: DataStoreFieldInfo] { get }
    var relationships: [DataStoreRelationInfo] { get }
    var relationshipsByName: [String: DataStoreRelationInfo] { get }
    func relationships(for table: DataStoreTableInfo) -> [DataStoreRelationInfo]
    var userInfo: [AnyHashable: Any]? { get }
}

public enum DataStoreFieldType: String {
    case boolean
    case string
    case date
    case float
    case decimal
    case double
    case binary
    case integer16
    case integer32
    case integer64
    case transformable
    case undefined
    case objectID
}

public protocol DataStoreFieldInfo {
    var name: String {get}
    var localizedName: String {get}
    var type: DataStoreFieldType {get}
    var isOptional: Bool {get}
    var userInfo: [AnyHashable: Any]? {get}
    var table: DataStoreTableInfo {mutating get}
    var validationPredicates: [NSPredicate] { get }
}

let kkeyMapping = "keyMapping"
let knameTransformer = "nameTransformer"

extension DataStoreFieldInfo {
    public var isMandatory: Bool {
        return !isOptional
    }

    public var mappedName: String? {
        return self.userInfo?[kkeyMapping] as? String
    }

    public var nameTransformer: String? {
        return self.userInfo?[kkeyMapping] as? String
    }
}

public protocol DataStoreRelationInfo {
    var name: String {get}

    var destinationTable: DataStoreTableInfo? { get }
    var inverseRelationship: DataStoreRelationInfo? { get }
    var maxCount: Int { get }
    var minCount: Int { get }
    var deleteRule: DeleteRule { get }
    var isToMany: Bool { get }
    var isOrdered: Bool { get }
    var isOptional: Bool {get}
    var userInfo: [AnyHashable: Any]? {get}

}
public enum DeleteRule: UInt {
    case noAction
    case nullify
    case cascade
    case deny
}

// MARK: DataStoreContext extension
extension DataStoreContext {

    public func create(in table: DataStoreTableInfo) -> Record? {
        return create(in: table.name)
    }

    public func getOrCreate(in table: DataStoreTableInfo, matching predicate: NSPredicate) throws -> Record? {
        return try getOrCreate(in: table.name, matching: predicate)
    }

    /// Create and updates values
    public func insert(in table: DataStoreTableInfo, values: [String: Any]) -> Record? {
        return insert(in: table.name, values: values)
    }

    /// Get records that match the predicate.
    public func get(in table: DataStoreTableInfo, matching predicate: NSPredicate) throws -> [Record]? {
        return try get(in: table.name, matching: predicate)
    }

    /// Update the records that match the predicate with the given `values`
    public func update(in table: DataStoreTableInfo, matching predicate: NSPredicate, values: [String: Any]) throws -> Bool {
        return try update(in: table.name, matching: predicate, values: values)
    }

    /// Check if there is records that match the predicate.
    public func has(in table: DataStoreTableInfo, matching predicate: NSPredicate) throws -> Bool {
        return try has(in: table.name, matching: predicate)
    }

    /// Delete records, which match the predicate.
    public func delete(in table: DataStoreTableInfo, matching predicate: NSPredicate? = nil) throws -> Bool {
        return try delete(in: table.name, matching: nil) // xxx remove predicate when updated
    }

}
