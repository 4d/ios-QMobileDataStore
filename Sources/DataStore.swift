//
//  DataStore.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 13/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Result

/// A delegate for `DataStore`
public protocol DataStoreDelegate: class {

    func dataStoreWillSave(_ dataStore: DataStore)
    func dataStoreDidSave(_ dataStore: DataStore)
    func objectsDidChange(dataStore: DataStore)

    func dataStoreWillLoad(_ dataStore: DataStore)
    func dataStoreDidLoad(_ dataStore: DataStore)
}

/// A store responsible to store record
public protocol DataStore {

    // MARK: Main

    /// load data store
    ///
    /// - parameters completionHandler: an handler to receive operation result.
    func load(completionHandler: CompletionHandler?)

    /// save data store
    ///
    /// - parameters completionHandler: an handler to receive operation result.
    func save(completionHandler: CompletionHandler?)

    /// drop data store
    ///
    /// - parameters completionHandler: an handler to receive operation result.
    func drop(completionHandler: CompletionHandler?)

    /// Is store loaded?
    var isLoaded: Bool { get }

    // MARK: Perform Task

    /// Perform a data store task by passing a context to a callback `block`.
    ///
    /// - parameters type: the type of context.
    /// - parameters block: the block to perform in data store foregroud context.
    ///
    /// - returns: true if action will be performed, false if store not ready.
    func perform(_ type: DataStoreContextType, _ block: @escaping (_ context: DataStoreContext, _ save: @escaping () throws -> Void) -> Void) -> Bool

    // MARK: Fetch request

    /// Create a fetch request for specific `tableName`
    /// - parameters tableName: the table name to request.`tableName`
    /// - parameters sortDescriptors: describte how to sort data
    ///
    /// - returns: a new fetch request
    func fetchRequest(tableName: String, sortDescriptors: [NSSortDescriptor]?) -> FetchRequest

    /// Create a fetched results controller for a fetch request.
    /// - parameters fetchRequest: the fetch request.
    /// - parameters sectionNameKeyPath: optionnal keypath for sectionName.
    ///
    /// - returns: a new fetch request
    func fetchedResultsController(fetchRequest: FetchRequest, sectionNameKeyPath: String?) -> FetchedResultsController

    // MARK: Observable

    /// A delegate to receive global notification on store
    var delegate: DataStoreDelegate? {get set}

    // MARK: Metadata

    /// Access to store metadata
    /// return nil if not ready
    var metadata: DataStoreMetadata? {get}

    // MARK: Structure
    var tablesInfo: [DataStoreTableInfo] {get}
    func tableInfo(for name: String) -> DataStoreTableInfo?

    // MARK: Result
    /// Result of data store operation
    typealias CompletionResult = Result<Void, DataStoreError>
    /// Closure result of data store operation
    typealias CompletionHandler = (CompletionResult) -> Void

}

public protocol DataStoreMetadata {

    subscript(key: String) -> Any? { get set }
}

public protocol DataStoreTableInfo {
    var name: String {get}
    var fields: [DataStoreFieldInfo] {get}
}
public typealias DataStoreFieldType = String
public protocol DataStoreFieldInfo {
    var name: String {get}
    var type: DataStoreFieldType {get}
}

// MARK: Error
/// An error from data store
public struct DataStoreError: Error {

    /// The underlying error.
    public let error: Error

    public init(_ error: Error) {
        self.error = error
    }

    /// Message from underlying error if core data error
    /// https://developer.apple.com/reference/coredata/1535452-validation_error_codes?language=swift
    public var coreDataMessage: String? {
        if error._domain == NSCocoaErrorDomain {
            let code = error._code
            if code == NSFileReadUnknownError /*256*/{
                return "Could not read data store file"
            } else {
                 return CoreDataStore.message(for: code)
            }
        }
        return nil
    }

}

// MARK: some shortcut
extension DataStore {

    /// Create a fetch request for specific `tableName`
    /// - parameters tableName: the table name to request.`tableName`
    ///
    /// - returns: a new fetch request
    public func fetchRequest(tableName: String) -> FetchRequest {
        return self.fetchRequest(tableName: tableName, sortDescriptors: nil)
    }

    /// Create a fetched results controller for specific `tableName`
    ///
    /// - parameters tableName the table name to request.
    ///
    /// - return a fetched results controller
    public func fetchedResultsController(tableName: String, sectionNameKeyPath: String? = nil) -> FetchedResultsController {
        return self.fetchedResultsController(fetchRequest: self.fetchRequest(tableName: tableName), sectionNameKeyPath: sectionNameKeyPath)
    }

    public func fetchedResultsController(fetchRequest: FetchRequest) -> FetchedResultsController {
        return self.fetchedResultsController(fetchRequest: fetchRequest, sectionNameKeyPath: nil)
    }
/*
    func load() {
        self.save(completionHandler: nil)
    }
    func save() {
        self.save(completionHandler: nil)
    }
    func drop() {
        self.drop(completionHandler: nil)
    }
*/
}
