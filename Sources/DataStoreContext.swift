//
//  DataStoreContext.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 16/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import Result

/// A context for data task
public protocol DataStoreContext: class {

    /// Create a new record and add it to data store.
    func create(in table: String) -> Record?

    /// Create a new record if there is no record that match the predicate, otherwise return the 
    /// first one that match.
    func getOrCreate(in table: String, matching predicate: NSPredicate) throws -> Record?

    /// Create and updates values
    func insert(in table: String, values: [String: Any]) -> Record?
    /// Get records that match the predicate.
    func get(in table: String, matching predicate: NSPredicate) throws -> [Record]?

    /// Update the records that match the predicate with the given `values`
    func update(in table: String, matching predicate: NSPredicate, values: [String: Any]) throws -> Bool

    /// Check if there is records that match the predicate.
    func has(in table: String, matching predicate: NSPredicate) throws -> Bool

    /// Delete a specific record.
    func delete(record: Record)

    /// Delete records, which match the predicate.
    func delete(in table: String, matching predicate: NSPredicate) throws -> Bool

    /// Removes everything from the undo stack, discards all insertions and deletions, and restores updated objects to their last committed values.
    func rollback()
}

extension DataStoreContext {

    /// Delete records.
    public func delete(records: [Record]) {
        for record in records {
            delete(record: record)
        }
    }

}

/// A type of DataStoreContext
public enum DataStoreContextType {
    case foreground
    case background
}
