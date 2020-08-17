//
//  CoreDataStore.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 13/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData

import Prephirences

import XCGLogger

private let sqlExtension = "sqlite"
private let sqlExtensions = ["-shm", "-wal"]

// MARK: CoreData store
@objc public class CoreDataStore: NSObject {

    public enum StoreType {
        case inMemory, sql(URL?)

        var type: String {
            switch self {
            case .inMemory:
                return NSInMemoryStoreType
            case .sql:
                return NSSQLiteStoreType
            }
        }

        public static let sqlDefault: StoreType = .sql(nil)
    }

    /// a default core data store
    static var `default` = CoreDataStore()

    /// The model name
    public let model: CoreDataObjectModel
    /// The model store type
    public let storeType: StoreType

    let fileManager: FileManager = .default

    // private not documented, see persistence store description fields
    var isReadOnly = false
    #if os(macOS)
    var shouldAddStoreAsynchronously = false
    let sqlitePragmas: [String: String] = [
        // "synchronous": "NORMAL",
        "journal_mode": "OFF",
        "temp_store": "MEMORY"
    ]
    #else
    var shouldAddStoreAsynchronously = true
    let sqlitePragmas: [String: String] = [:]
    #endif
    var shouldMigrateStoreAutomatically = true
    var shouldInferMappingModelAutomatically = true

    let automaticMerge = true // /!\ do not change without testing

    var dropIfMigrationFailed: Bool = true

    private var observers: [Any] = [Any]()

    /// The bundle which contains the model
    internal var modelBundle: Bundle = Bundle.dataStore

    open weak var delegate: DataStoreDelegate?

    /// A read-only flag indicating if the persistent store is loaded.
    public fileprivate (set) var isLoaded = false

    /// Initializes using a model and store type.
    ///
    /// - parameter model: The model.
    /// - parameter storeType: the store type (default: sql).
    ///
    /// - returns: The new `QMobileCoreDataStore` instance.
    public init(model: CoreDataObjectModel = .default, storeType: StoreType = .sqlDefault) {
        self.model = model
        self.storeType = storeType

        super.init()

        initObservers()
    }

    fileprivate func initObservers(center: NotificationCenter = NotificationCenter.default) {
        let notificationQueue: OperationQueue = .main

        observers.append(center.addObserver(forName: .NSManagedObjectContextDidSave, object: nil, queue: notificationQueue) { [weak self] notification in
            guard let this = self else {
                return
            }
            guard let moc = notification.object as? NSManagedObjectContext  else {
                // not merge if two are the same context
                return
            }
            this.delegate?.dataStoreDidSave(this, context: moc) // XXX maybe move code if only for viewContext

            /*
             let inserted = notification[.inserted]
             let updated = notification[.updated]
             let deleted = notification[.deleted]
             */
            let viewContext = this.viewContext
            guard moc != viewContext  else {
                // not merge if two are the same context
                return
            }
            if this.automaticMerge {
                this.save()
                // moc.mergeChanges(fromContextDidSave: notification) // just to study bug
            } else {

                viewContext.perform {
                    // notify observer before merging
                    this.delegate?.dataStoreWillMerge(this, context: viewContext, with: moc)
                    Notification(name: .dataStoreWillMerge, userInfo: notification.userInfo).post(.dataStore)

                    // merge change from children context

                    /*
                     let insertedRecords = viewContext.insertedRecords
                     let updatedRecords = viewContext.updatedRecords
                     let registeredObjects = viewContext.registeredRecords*/

                    viewContext.mergeChanges(fromContextDidSave: notification)

                    /* let insertedRecordsAfter = viewContext.insertedRecords
                     let updatedRecordsAfter = viewContext.updatedRecords
                     let registeredObjectsAfter = viewContext.registeredRecords*/

                    // save
                    this.save() // XXX will save viewContext if change
                    /*let insertedRecordsAfterSave = viewContext.insertedRecords
                     let updatedRecordsAfterSave = viewContext.updatedRecords
                     let registeredObjectsAfterSave = viewContext.registeredRecords*/

                    // notify observer after merging
                    this.delegate?.dataStoreDidMerge(this, context: viewContext, with: moc)
                    Notification(name: .dataStoreDidMerge, userInfo: notification.userInfo).post(.dataStore)
                    // notify observer after merging
                    this.delegate?.dataStoreDidMerge(this, context: viewContext, with: moc)
                    Notification(name: .dataStoreDidMerge, userInfo: notification.userInfo).post(.dataStore)
                }
            }
        })
        observers.append(center.addObserver(forName: .NSManagedObjectContextWillSave, object: nil, queue: notificationQueue) { [weak self] notification in
            guard let this = self else {
                return
            }
            guard let moc = notification.object as? NSManagedObjectContext  else {
                // not merge if two are the same context
                return
            }
            this.delegate?.dataStoreWillSave(this, context: moc)
        })
        observers.append(center.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: nil, queue: notificationQueue) { [weak self] notification in
            guard let this = self else {
                return
            }
            guard let moc = notification.object as? NSManagedObjectContext  else {
                // not merge if two are the same context
                return
            }
            //notification.userInfo["invalidateAll"]
            this.delegate?.objectsDidChange(dataStore: this, context: moc)
        })
    }

    deinit {
        self.deinitObservers()
    }

    fileprivate func deinitObservers(center: NotificationCenter = NotificationCenter.default) {
        for observer in observers {
            center.removeObserver(observer)
        }
    }

    // MARK: computed variables

    fileprivate var _persistentContainer: NSPersistentContainer?
    public var persistentContainer: NSPersistentContainer {
        if let persistentContainer = _persistentContainer {
            return persistentContainer
        }
        let value = setupContainer()
        _persistentContainer = value
        return value
    }

    private func setupContainer() -> NSPersistentContainer {
        let modelName = self.model.name()
        guard let managedObjectModel = self.model.model() else {
            return NSPersistentContainer(name: modelName)
        }

        let container = NSPersistentContainer(name: modelName, managedObjectModel: managedObjectModel)
        let description = self.storeDescription(with: self.storeURL) // XXX

        container.persistentStoreDescriptions = [description]
        logger.verbose("\(container.persistentStoreDescriptions)")
        return container
    }
    private func unsetupContainer() {
        _persistentContainer = nil
    }

    fileprivate var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        return persistentContainer.persistentStoreCoordinator
    }

    fileprivate var persistentStore: NSPersistentStore? {
        return self.persistentStoreCoordinator.persistentStores.first
    }

    internal var viewContext: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }

    internal func newBackgroundContext() -> NSManagedObjectContext {
        // let backgroundContext = self.persistentContainer.newBackgroundContext()
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        if automaticMerge {
            backgroundContext.parent = viewContext
            backgroundContext.automaticallyMergesChangesFromParent = true
            assert(backgroundContext.persistentStoreCoordinator != nil)
        }
        if backgroundContext.persistentStoreCoordinator == nil {
            backgroundContext.persistentStoreCoordinator = self.persistentContainer.persistentStoreCoordinator
        }
        return backgroundContext
    }

    fileprivate func storeDescription(with url: URL?) -> NSPersistentStoreDescription {
        let description: NSPersistentStoreDescription
        if let url = url {
            description = NSPersistentStoreDescription(url: url)
        } else {
            description = NSPersistentStoreDescription() // transient
        }
        description.type = self.storeType.type
        description.isReadOnly = self.isReadOnly
        description.shouldAddStoreAsynchronously = self.shouldAddStoreAsynchronously
        description.shouldInferMappingModelAutomatically = self.shouldInferMappingModelAutomatically
        description.shouldMigrateStoreAutomatically = self.shouldMigrateStoreAutomatically
        if !sqlitePragmas.isEmpty {
            description.setOption(sqlitePragmas as NSDictionary, forKey: NSSQLitePragmasOption)
        }
        return description
    }

    fileprivate var storeDirectoryURL: URL? {
        switch self.storeType {
        case .inMemory:
            return nil
        case .sql(let url):
            return url ?? NSPersistentContainer.defaultDirectoryURL()
        }
    }

    fileprivate func copyEmbeddedDatabase(to storeURL: URL) {
        let modelName = self.model.name()
        if let dbURL = Bundle.main.url(forResource: modelName, withExtension: sqlExtension) {
            if fileManager.fileExists(at: dbURL) {
                do {
                    try fileManager.copyItem(at: dbURL, to: storeURL)
                    do {
                        let parentDir = storeURL.deletingLastPathComponent()
                        for suffix in sqlExtensions {
                            if let dbSuffixedURL = Bundle.main.url(forResource: modelName, withExtension: sqlExtension + suffix) {
                                try fileManager.copyItem(at: dbSuffixedURL, to: parentDir.appendingPathComponent(dbSuffixedURL.lastPathComponent))
                            }
                        }
                    } catch {
                        logger.error("Failed to import one of the database files: \(error)")
                        try? drop(storeURL: storeURL)
                    }
                } catch {
                    logger.error("Failed to import database file \(error)")
                }
            }
        }
    }

    var storeURL: URL? {
        guard let storeDirectoryURL = self.storeDirectoryURL else {
            return nil
        }
        try? fileManager.createDirectory(at: storeDirectoryURL, withIntermediateDirectories: true)

        let modelName = self.model.name()
        let storeURL = storeDirectoryURL.appendingPathComponent(modelName).appendingPathExtension(sqlExtension)
        if !fileManager.fileExists(at: storeURL) {
            copyEmbeddedDatabase(to: storeURL)
        }

        return storeURL
    }

    fileprivate var storeURLExists: Bool {
        guard let url = self.storeURL else {
            return false
        }
        return url.isFileURL && fileManager.fileExists(atPath: url.path)
    }
}

// MARK: Structure

struct CoreDataStoreMetaData: DataStoreMetadata {

    let persistentStore: NSPersistentStore

    subscript(key: String) -> Any? {
        get {
            return persistentStore.metadata[key]
        }
        set {
            persistentStore.metadata[key] = newValue
        }
    }

}

extension CoreDataStore: DataStore {

    // MARK: Structures
    public var tablesInfo: [DataStoreTableInfo] {
        let entities = persistentContainer.managedObjectModel.entities
        return entities.filter { $0.name != nil }.map { CoreDataStoreTableInfo(entity: $0) }
    }

    public func tableInfo(for name: String) -> DataStoreTableInfo? {
        let entities = persistentContainer.managedObjectModel.entities
        for entity in entities where entity.name == name {
            return CoreDataStoreTableInfo(entity: entity)
        }
        return nil
    }

    // MARK: Metadata
    public var metadata: DataStoreMetadata? {
        guard let persistentStore = self.persistentStore else {
            return nil
        }
        return CoreDataStoreMetaData(persistentStore: persistentStore)
    }

    // MARK: Main

    public func load(completionHandler: CompletionHandler? = nil) {
        if isLoaded {
            self.delegate?.dataStoreAlreadyLoaded(self)
            return
        }
        // CLEAN: bug, could be called two times during migration fail. could extract function or add a isLoading boolean with didSet
        self.delegate?.dataStoreWillLoad(self)

        persistentContainer.loadPersistentStores { [unowned self] (storeDescription, error) in
            var doNotify = true
            var result: DataStore.CompletionResult = .success(())
            if let error = error {

                if error._domain == NSCocoaErrorDomain {
                    let code = error._code
                    if code == NSFileReadUnknownError /*256*/{
                        // We can do anything... file system issue, or file path issue
                        logger.error("Could not load datastore \(error)")
                        completionHandler?(.failure(DataStoreError(error)))
                    } else {
                        if let message = CocoaError.Code.message(for: code) {
                            logger.error(message)
                        }

                        if self.dropIfMigrationFailed {
                            logger.warning("Data will be erased from local datastore. Get data from an other source will be necessary")

                            if let url = storeDescription.url {
                                do {
                                    try self.drop(storeURL: url)

                                    doNotify = false // let next load notify
                                    self.dropIfMigrationFailed = false // try only one time
                                    self.load(completionHandler: completionHandler)
                                } catch let dropError {
                                    logger.error("Failed to drop data store files \(dropError).")
                                    result = .failure(DataStoreError(error))
                                }
                            } else {
                                result = .failure(DataStoreError(error))
                            }
                        } else {
                            result = .failure(DataStoreError(error))
                        }
                    }

                } else {
                    // Unknown error
                    logger.error("Unknown error \(error)")
                    result = .failure(DataStoreError(error))
                }

            } else {
                // Normal case
                self.isLoaded = true
                self.delegate?.dataStoreDidLoad(self)
                logger.verbose("store loaded: \(storeDescription)")
                // .success
            }
            if doNotify {
                Notification(name: .dataStoreLoaded, object: result).post(.dataStore)
                completionHandler?(result)
            }
        }
    }

    /*
     public var entityInfo: [(String, [String])] {
        return self.managedObjectModel.entities.map { ($0.name ?? "", Array($0.attributesByName.keys)) }
    }*/

    public func save(completionHandler: CompletionHandler? = nil) {
        self.viewContext.perform {
            var result: DataStore.CompletionResult = .success(())
            do {
                if self.viewContext.hasChanges {
                    try self.viewContext.save()
                }
            } catch {
                result = .failure(DataStoreError(error))
            }
            Notification(name: .dataStoreSaved, object: result).post(.dataStore)
            completionHandler?(result)
        }
    }

    /**
     Drops the data store.
     */
    public func drop(completionHandler: CompletionHandler? = nil) {
        self.viewContext.performAndWait {
            var result: DataStore.CompletionResult = .success(())
            self.viewContext.reset()

            self.persistentStoreCoordinator.performAndWait {
                let isLoaded = self.isLoaded
                self.isLoaded = false
                guard let store = self.persistentStore else {
                    do {
                        // Not loaded yet, try to remove store url files
                        if !isLoaded, let url = self.storeURL, url != NSPersistentStore.defaultURL {
                            try self.drop(storeURL: url)
                        }
                    } catch {
                        result = .failure(DataStoreError(error))
                    }
                    unsetupContainer()
                    Notification(name: .dataStoreDropped, object: result).post(.dataStore)
                    completionHandler?(result)
                    return
                }
                // Do not try to remove /dev/null files
                if store.isTransient {
                    Notification(name: .dataStoreDropped, object: result, userInfo: ["transient": true]).post(.dataStore)
                    completionHandler?(result)
                    return
                }

                self.unsetupContainer()

                // get the store url
                guard let storeURL = store.url, storeURL.isFileURL else {
                    Notification(name: .dataStoreDropped, object: result, userInfo: ["noFile": true]).post(.dataStore)
                    completionHandler?(result)
                    return
                }

                do {
                    // self.persistentStoreCoordinator.remove(store)
                    if persistentStoreCoordinator.persistentStores.first?.url != nil {
                        print("Missing first store URL - could not destroy")
                        try self.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: self.storeType.type, options: store.options)
                    }

                    // remove the files
                    try self.drop(storeURL: storeURL)
                } catch {
                    result = .failure(DataStoreError(error))
                }
                Notification(name: .dataStoreDropped, object: result).post(.dataStore)
                completionHandler?(result)
            }
        }
    }

    // remove sqlite files
    func drop(storeURL: URL) throws {
        try fileManager.removeItemIfExists(at: storeURL)
        let name = storeURL.lastPathComponent
        for suffix in sqlExtensions {
            try fileManager.removeItemIfExists(at: storeURL.deletingLastPathComponent().appendingPathComponent("\(name)\(suffix)"))
        }
    }

}

// MARK: Perform Task

extension CoreDataStore {

    func perform(_ type: DataStoreContextType, wait: Bool = false, _ block: @escaping (_ context: DataStoreContext) -> Void) -> Bool {
        return self.perform(type, wait: wait, blockName: nil, block)
    }

    public func perform(_ type: DataStoreContextType, wait: Bool = false, blockName: String?, _ block: @escaping (_ context: DataStoreContext) -> Void) -> Bool {
        if !isLoaded {
            logger.error("Perform action on store but not loaded yet. Type: \(type) \(blockName ?? "")")
            // XXX here could do better by waiting to data store loading. For instance by registering the task on data store load event.
            // but maybe the data store will never load so maybe a timeout...
            return false
        }
        var userInfo: [String: Any] = ["in": type, "wait": wait]
        if let blockName = blockName {
            userInfo["block"] = blockName // useful for debugging request, have some info on the block executed
        }
        Notification(name: .dataStoreWillPerformAction, object: type, userInfo: userInfo).post(.dataStore)

        let blockTask: ((NSManagedObjectContext) -> Void) = { context in
            block(context)
            Notification(name: .dataStoreDidPerformAction, object: type, userInfo: userInfo).post(.dataStore)
        }

        doPerform(type, wait, blockTask)
        return true
    }

    fileprivate func doPerform(_ type: DataStoreContextType, _ wait: Bool, _ blockTask: @escaping ((NSManagedObjectContext) -> Void)) {
        switch type {
        case .foreground:
            if wait {
                performAndWaitForegroundTask(blockTask)
            } else {
                performForegroundTask(blockTask)
            }
        case .background:
            if wait {
                performAndWaitBackgroundTask(blockTask)
            } else {
                performBackgroundTask(blockTask)
            }
        }
    }

    func performForegroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        self.viewContext.perform {
            block(self.viewContext)
        }
    }
    func performAndWaitForegroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        self.viewContext.performAndWait {
            block(self.viewContext)
        }
    }

    func performBackgroundTask(newContext: Bool = true, _ block: @escaping (NSManagedObjectContext) -> Void) {
        if newContext {
            let context = self.newBackgroundContext()
            context.perform {
                block(context)
            }
        } else {
            // /!\if use this code, no parent for context
            self.persistentContainer.performBackgroundTask(block)
        }
    }

    func performAndWaitBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = self.newBackgroundContext()
        context.performAndWait { // XXX no method in container...
            block(context)
        }
    }

}
