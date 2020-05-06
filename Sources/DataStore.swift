//
//  DataStore.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 13/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

/// A store responsible to store record
public protocol DataStore {

    // MARK: Result
    /// Result of data store operation
    typealias CompletionResult = Result<Void, DataStoreError>
    /// Closure result of data store operation
    typealias CompletionHandler = (CompletionResult) -> Void

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
    /// - parameters blockName: name the block, for debug purpose.
    /// - parameters block: the block to perform in data store foregroud context. Block provide context, and a safe save closure.
    ///
    /// - returns: true if action will be performed, false if store not ready.
    func perform(_ type: DataStoreContextType, wait: Bool, blockName: String?, _ block: @escaping (_ context: DataStoreContext) -> Void) -> Bool

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

    /// Closure to save data store.
    /// @throw DataStoreError
    typealias SaveClosure = () throws -> Void

}

// MARK: some shortcut
extension DataStore {

    /// Perform a data store task by passing a context to a callback `block`.
    ///
    /// - parameters type: the type of context.
    /// - parameters blockName: a name for the block, debug purpose.
    /// - parameters block: the block to perform in data store foregroud context.
    ///   in block you receive
    ///       - the context to perform operation
    ///       - a save closure to save the context, ie. commit your operation. could throw DataStoreError.
    ///
    /// - returns: true if action will be performed, false if store not ready.
    public func perform(_ type: DataStoreContextType, wait: Bool = false, blockName: String? = nil, _ block: @escaping (_ context: DataStoreContext) -> Void) -> Bool {
        return self.perform(type, wait: wait, blockName: blockName, block)
    }

    public func fetchedResultsController(fetchRequest: FetchRequest, sectionNameKeyPath: String?) -> FetchedResultsController {
        return self.fetchedResultsController(fetchRequest: fetchRequest, sectionNameKeyPath: sectionNameKeyPath, context: nil)
    }

    /// Create a fetch request for specific `tableName`
    /// - parameters tableName: the table name to request.`tableName`
    ///
    /// - returns: a new fetch request
    /*public func fetchRequest(tableName: String) -> FetchRequest {
        return self.fetchRequest(tableName: tableName, sortDescriptors: nil)
    }*/

    /// Create a fetched results controller for specific `tableName`
    ///
    /// - parameters tableName the table name to request.
    ///
    /// - return a fetched results controller
    public func fetchedResultsController(tableName: String, sectionNameKeyPath: String? = nil, sortDescriptors: [NSSortDescriptor]) -> FetchedResultsController {
        return self.fetchedResultsController(fetchRequest: self.fetchRequest(tableName: tableName, sortDescriptors: sortDescriptors), sectionNameKeyPath: sectionNameKeyPath)
    }

    public func fetchedResultsController(fetchRequest: FetchRequest) -> FetchedResultsController {
        return self.fetchedResultsController(fetchRequest: fetchRequest, sectionNameKeyPath: nil)
    }

}
