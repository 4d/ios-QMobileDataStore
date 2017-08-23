//
//  DataStore.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 13/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Result

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
    /// - parameters wait: wait until task end. Default false.
    /// - parameters block: the block to perform in data store foregroud context.
    ///
    /// - returns: true if action will be performed, false if store not ready.
    func perform(_ type: DataStoreContextType, wait: Bool, _ block: @escaping (_ context: DataStoreContext, _ save: @escaping () throws -> Void) -> Void) -> Bool

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
    /// - parameters context: context of fetch operation. Default view context
    ///
    /// - returns: a new fetch request
    func fetchedResultsController(fetchRequest: FetchRequest, sectionNameKeyPath: String?, context: DataStoreContext?) -> FetchedResultsController

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

extension DataStore {

    /// Perform a data store task by passing a context to a callback `block`.
    ///
    /// - parameters type: the type of context.
    /// - parameters block: the block to perform in data store foregroud context.
    ///   in block you receive
    ///       - the context to perform operation
    ///       - a save closure to save the context, ie. commit your operation. could throw DataStoreError.
    ///
    /// - returns: true if action will be performed, false if store not ready.
    public func perform(_ type: DataStoreContextType, _ block: @escaping (_ context: DataStoreContext, _ save: @escaping () throws -> Void) -> Void) -> Bool {
        return self.perform(type, wait: false, block)
    }

    public func fetchedResultsController(fetchRequest: FetchRequest, sectionNameKeyPath: String?) -> FetchedResultsController {
        return self.fetchedResultsController(fetchRequest: fetchRequest, sectionNameKeyPath: sectionNameKeyPath, context: nil)
    }

    /// Observe notification from data store
    /// When registering for a notification, the opaque observer that is returned should be stored so it can be removed later using `unobserve` method.
    public func observe(_ name: Notification.Name, queue: OperationQueue? = nil, using: @escaping (Notification) -> Void) -> NSObjectProtocol {
        // XXX not compatible if multiple data store...could filter on current dataStore
        return NotificationCenter.dataStore.addObserver(forName: name, object: nil, queue: queue, using: using)
    }

    /// Unobserve notification from data store
    public func unobserve(_ observer: NSObjectProtocol) {
        NotificationCenter.dataStore.removeObserver(observer)
    }

    /// When registering for a notification, the opaque observer that is returned should be stored so it can be removed later using `unobserve` method.
    public func onLoad(queue: OperationQueue? = nil, using: @escaping (Notification) -> Void) -> NSObjectProtocol {
        return observe(.dataStoreLoaded, queue: queue, using: using)
    }

    /// When registering for a notification, the opaque observer that is returned should be stored so it can be removed later using `unobserve` method.
    public func onDrop(queue: OperationQueue? = nil, using: @escaping (Notification) -> Void) -> NSObjectProtocol {
        return observe(.dataStoreDropped, queue: queue, using: using)
    }

    /// When registering for a notification, the opaque observer that is returned should be stored so it can be removed later using `unobserve` method.
    public func onSave(queue: OperationQueue? = nil, using: @escaping (Notification) -> Void) -> NSObjectProtocol {
        return observe(.dataStoreSaved, queue: queue, using: using)
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
