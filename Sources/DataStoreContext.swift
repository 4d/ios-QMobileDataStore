//
//  DataStoreContext.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 16/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

/// A context for data task
public protocol DataStoreContext: class {

    /// Create a new record and add it to data store.
    func create(in table: String) -> Record?

    /// Create a new record if there is no record that match the predicate, otherwise return the 
    /// first one that match.
    func getOrCreate(in table: String, matching predicate: NSPredicate, created: inout Bool) throws -> Record?

    /// Create and updates values
    func insert(in table: String, values: [String: Any]) -> Record?
    /// Get records that match the predicate.
    func get(in table: String, matching predicate: NSPredicate) throws -> [Record]?

    /// Update the records that match the predicate with the given `values`
    func update(in table: String, matching predicate: NSPredicate, values: [String: Any]) throws -> Bool

    /// Check if there is records that match the predicate.
    func has(in table: String, matching predicate: NSPredicate) throws -> Bool

    /// Check if the object exist in context
    func has(record: Record) -> Bool

    /// Delete a specific record.
    func delete(record: Record)

    /// Delete records, which match the predicate.
    func delete(in table: String, matching predicate: NSPredicate?) throws -> Int

    /// Save modification to database.
    func commit() throws
    /// Removes everything from the undo stack, discards all insertions and deletions, and restores updated objects to their last committed values.
    func rollback()
    /// Returns the context to its base state.
    func reset()

    /// Perform an operation on context queue
    /// @param wait: if true wait end of block operation
    /// @block block: the block to execute
    func perform(wait: Bool, _ block: @escaping () -> Void)

    /// Perform an operation on new child context queue
    /// @param wait: if true wait end of block operation
    /// @block block: the block to execute
    func performOnChildContext(wait: Bool, _ block: @escaping (DataStoreContext) -> Void)

    /// Fetch records according to request
    func fetch(_ request: FetchRequest) throws -> [Record]
    /// Count records that match request
    func count(for request: FetchRequest) throws -> Int
    /// Count element in table
    func count(in table: String) throws -> Int
    /// Execute a function
    func function(_ function: String, in tableName: String, for fieldNames: [String], with predicate: NSPredicate?) throws -> [Double]
    func function(_ function: String, request: FetchRequest, for fieldNames: [String]) throws -> [Double]

    // func undo()
    // func redo()

    /// Type of context
    var type: DataStoreContextType {get}

    // Info
    var name: String? {get set}
    var userInfo: NSMutableDictionary { get }
    var hasChanges: Bool { get }

    /// records history
    var insertedRecords: [Record] { get }
    var updatedRecords: [Record] { get }
    var deletedRecords: [Record] { get }
    var pendingRecords: [Record] { get }
    // Object in the context
    var registeredRecords: [Record] { get }

    func refresh(_ record: Record, mergeChanges flag: Bool)
    func detectConflicts(for record: Record)
    /* calls -refreshObject:mergeChanges: on all currently registered objects with this context.  It handles dirtied objects and clearing the context reference queue */
    func refreshAllRecords()

    /// Parent context if any.
    var parentContext: DataStoreContext? { get set }
    var automaticallyMergesChangesFromParent: Bool { get set }

    /// Structures
    var tablesInfo: [DataStoreTableInfo] { get }
    func tableInfo(for name: String) -> DataStoreTableInfo?

    /// - returns: a new fetch request
    func fetchRequest(tableName: String, sortDescriptors: [NSSortDescriptor]?) -> FetchRequest

    typealias CompletionHandler = (Result<Void, DataStoreError>) -> Void // DataStore.CompletionHandler
}

extension DataStoreContext {

    public func fetchRequest(tableName: String) -> FetchRequest {
        return fetchRequest(tableName: tableName, sortDescriptors: nil)
    }

    /*** Get the record associated with the change type */
    public func records(for changeType: DataStoreChangeType) -> [Record] {
        switch changeType {
        case .updated:
            return self.updatedRecords
        case .deleted:
            return self.deletedRecords
        case .inserted:
            return self.insertedRecords
        }
    }

    /// Commit data store context modifications.
    /// @param completionHandler : callback to receive result
    public func commit(completionHandler: CompletionHandler) {
        do {
            try self.commit()
            completionHandler(.success(()))
        } catch {
            completionHandler(.failure(DataStoreError.error(from: error)))
        }
    }

}

extension DataStoreContext {

    public func function(_ function: String, in tableName: String, for fieldNames: [String]) throws -> [Double] {
        return try self.function(function, in: tableName, for: fieldNames, with: nil)
    }

    public func sum(in tableName: String, for fieldNames: [String], with predicate: NSPredicate? = nil) throws -> [Double] {
        return try self.function("sum:", in: tableName, for: fieldNames, with: predicate)
    }

    public func sum(tableName: String, for fieldName: String, with predicate: NSPredicate? = nil) throws -> Double {
        return try self.sum(in: tableName, for: [fieldName], with: predicate).first ?? 0
    }

    public func max(in tableName: String, for fieldNames: [String], with predicate: NSPredicate? = nil) throws -> [Double] {
        return try self.function("max:", in: tableName, for: fieldNames, with: predicate)
    }

    public func max(in tableName: String, for fieldName: String, predicate: NSPredicate? = nil) throws -> Double {
        return try self.max(in: tableName, for: [fieldName], with: predicate).first ?? 0
    }

    public func min(in tableName: String, for fieldNames: [String], predicate: NSPredicate? = nil) throws -> [Double] {
        return try  self.function("min:", in: tableName, for: fieldNames, with: predicate)
    }

    public func min(in tableName: String, for fieldName: String, predicate: NSPredicate? = nil) throws -> Double {
        return try self.min(in: tableName, for: [fieldName], predicate: predicate).first ?? 0
    }

    public func avg(in tableName: String, for fieldNames: [String], predicate: NSPredicate? = nil) throws -> [Double] {
        return try self.function("average:", in: tableName, for: fieldNames, with: predicate)
    }

    public func avg(in tableName: String, for fieldName: String, predicate: NSPredicate? = nil) throws -> Double {
        return try self.avg(in: tableName, for: [fieldName], predicate: predicate).first ?? 0
    }

}

extension DataStoreContext {

    /// Delete records.
    public func delete(records: [Record]) {
        for record in records {
            delete(record: record)
        }
    }

    /// Delete all the records in table.
    public func delete(in table: String) throws -> Int {
        return try delete(in: table, matching: nil)
    }

    /// Perform an operation on context queue
    public func perform(_ block: @escaping () -> Void) {
        perform(wait: false, block)
    }

    /// Perform an operation on child context queue
    public func performOnChildContext(wait: Bool, _ block: @escaping (DataStoreContext) -> Void) {
        self.performOnChildContext(wait: false, block)
    }

}

extension DataStoreContext {

    /// Dump data store by tables
    /// @parameter publish receive data by page
    public func dump(publish: (DataStoreTableInfo, Result<[Record], DataStoreError>) -> Void) {
        let tables = self.tablesInfo
        for table in tables {
            let request = self.fetchRequest(tableName: table.name)
            do {
                let records = try self.fetch(request)
                publish(table, .success(records))
            } catch {
                publish(table, .failure(DataStoreError.error(from: error)))
            }
        }
    }

}

// MARK: Enums
/// A type of DataStoreContext
public enum DataStoreContextType: Equatable {
    /// The context associated with the main queue. (Used to display data)
    case foreground
    /// Context used for background task, using a private queue.
    case background
}

/// An enum for history change
public enum DataStoreChangeType {
    /// Record has been inserted
    case inserted
    /// Record has been updated
    case updated
    /// Record has been deleted
    case deleted
}

// iOS11 manage history to send change to server: https://developer.apple.com/documentation/coredata/nspersistenthistorychange?language=objc
