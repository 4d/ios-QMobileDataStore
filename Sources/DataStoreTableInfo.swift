//
//  DataStoreTable.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 24/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

/// Information about a table structure in data store.
public protocol DataStoreTableInfo {
    /// The table name.
    var name: String {get}
    /// The localized name if any.
    var localizedName: String {get}
    /// Is table abstract ie. could not instanciante a concrete type.
    var isAbstract: Bool {get}
    /// List of fields.
    var fields: [DataStoreFieldInfo] {get}
    /// List of fields indexed by name.
    var fieldsByName: [String: DataStoreFieldInfo] { get }
    /// List of relations.
    var relationships: [DataStoreRelationInfo] { get }
    /// List of relations indexed by name.
    var relationshipsByName: [String: DataStoreRelationInfo] { get }

    /// List of all properties. Fields, relation, others (fetched/calculated)
    var properties: [DataStorePropertyInfo] { get }
    /// List of all properties indexed by name.
    var propertiesByName: [String: DataStorePropertyInfo] { get }

    /// Get the relations with passed table.
    /// @param table : the table in relation with the current one.
    func relationships(for table: DataStoreTableInfo) -> [DataStoreRelationInfo]
    /// Custom user information
    var userInfo: [AnyHashable: Any]? { get set }
}

extension DataStoreContext {

    // MARK: Operation using `DataStoreTableInfo`

    /// Create a new record and add it to data store.
    public func create(in table: DataStoreTableInfo) -> Record? {
        return create(in: table.name)
    }

    /// Create a new record if there is no record that match the predicate, otherwise return the first one that match.
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
    public func delete(in table: DataStoreTableInfo, matching predicate: NSPredicate? = nil) throws -> Int {
        return try delete(in: table.name)
    }

    /// Count element in table
    public func count(in table: DataStoreTableInfo) throws -> Int {
        return try count(in: table.name)
    }
}
