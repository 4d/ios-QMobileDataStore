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
import Result
import XCGLogger

// MARK: shared
extension DataStore {

    /// shared DataStore
    public static var shared: DataStore {
        return CoreDataStore.default
    }
}

// MARK: CoreData store
@objc internal class CoreDataStore: NSObject {

    @objc enum StoreType: Int {
        case inMemory, sql

        var type: String {
            switch self {
            case .inMemory:
                return NSInMemoryStoreType
            case .sql:
                return NSSQLiteStoreType
            }
        }
    }

    /// a default core data store
    static var `default` = CoreDataStore()

    /// The model name
    open let model: CoreDataObjectModel
    /// The model store type
    open let storeType: StoreType

    // private not documented, see persistence store description fields
    var isReadOnly = false
    var shouldAddStoreAsynchronously = true
    var shouldMigrateStoreAutomatically = true
    var shouldInferMappingModelAutomatically = true

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
    internal init(model: CoreDataObjectModel = CoreDataObjectModel.named(Bundle.dataStore[Bundle.dataStoreKey] as? String ?? "Structures", Bundle.dataStore), storeType: StoreType = .sql) {
        self.model = model
        self.storeType = storeType

        super.init()

        self.viewContext.automaticallyMergesChangesFromParent = true

        initObservers()
    }

    fileprivate func initObservers(center: NotificationCenter = NotificationCenter.default) {
        // here false positive for discarded_notification_center_observer
        //swiftlint:disable discarded_notification_center_observer
        observers.append(center.addObserver(forName: .NSManagedObjectContextDidSave, object: nil, queue: .main) { [unowned self] note in

            if let moc = note.object as? NSManagedObjectContext {
                if moc != self.viewContext {
                    self.viewContext.perform {
                        Notification(name: .dataStoreWillMerge).post(.dataStore)
                        self.viewContext.mergeChanges(fromContextDidSave: note)
                        Notification(name: .dataStoreDidMerge).post(.dataStore)
                        self.save()
                    }
                }
            }

            self.delegate?.dataStoreDidSave(self)
        })
        observers.append(center.addObserver(forName: .NSManagedObjectContextWillSave, object: nil, queue: .main) { [unowned self] _ in
            self.delegate?.dataStoreWillSave(self)
        })
        observers.append(center.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: nil, queue: .main) { [unowned self] _ in
            self.delegate?.objectsDidChange(dataStore: self)
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
    fileprivate lazy var persistentContainer: NSPersistentContainer = {
        let modelName = self.model.name()
        guard let managedObjectModel = self.model.model() else {
            return NSPersistentContainer(name: modelName)
        }

        let container = NSPersistentContainer(name: modelName, managedObjectModel: managedObjectModel)
        let description = self.storeDescription(with: self.storeURL) // XXX

        container.persistentStoreDescriptions = [description]
        logger.verbose("\(container.persistentStoreDescriptions)")

        return container
    }()

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
        // let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        // backgroundContext.parent = viewContext
        return self.persistentContainer.newBackgroundContext()
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

        return description
    }

    fileprivate var storeDirectoryURL: URL? {
        switch self.storeType {
        case .inMemory:
            return nil
        case .sql:
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        }
    }

    var storeURL: URL? {
        var storeURL = self.storeDirectoryURL

        if let storeDirectoryURL = storeURL {
            try? FileManager.default.createDirectory(at: storeDirectoryURL, withIntermediateDirectories: true)
        }

        storeURL?.appendPathComponent(self.model.name())
        storeURL?.appendPathExtension("sqlite")

        return storeURL
    }

    fileprivate var storeURLExists: Bool {
        guard let url = self.storeURL else {
            return false
        }
        return url.isFileURL && FileManager.default.fileExists(atPath: url.path)
    }
}

// MARK: Structure

struct CoreDataStoreTableInfo: DataStoreTableInfo {
    let entity: NSEntityDescription

    var fields: [DataStoreFieldInfo] {
        return entity.attributesByName.values.map { CoreDataStoreFieldInfo(attribute: $0) }
    }

    var name: String {
       return self.entity.name!
    }
}

struct CoreDataStoreFieldInfo: DataStoreFieldInfo {
    let attribute: NSAttributeDescription
    var name: String {
        return attribute.name
    }

    var type: DataStoreFieldType {
        return self.attribute.attributeType.coreData
    }
}

extension NSAttributeType {
    var coreData: String {
        switch self {
        case .binaryDataAttributeType:
            return "Binary"
        case .booleanAttributeType:
            return "Boolean"
        case .dateAttributeType:
            return "Date"
        case .decimalAttributeType:
            return "Decimal"
        case .doubleAttributeType:
            return "Double"
        case .floatAttributeType:
            return "Float"
        case .integer16AttributeType:
            return "Integer 16"
        case .integer32AttributeType:
            return "Integer 32"
        case .integer64AttributeType:
            return "Integer 64"
        case .stringAttributeType:
            return "String"
        case .transformableAttributeType:
            return "Transformable"
        case .objectIDAttributeType:
            return "Object ID"
        case .undefinedAttributeType:
            return ""
        }
    }
}

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
    var tablesInfo: [DataStoreTableInfo] {
        let entities = persistentContainer.managedObjectModel.entities
        return entities.filter { $0.name != nil }.map { CoreDataStoreTableInfo(entity: $0) }
    }

    func tableInfo(for name: String) -> DataStoreTableInfo? {
        let entities = persistentContainer.managedObjectModel.entities
        for entity in entities where entity.name == name {
            return CoreDataStoreTableInfo(entity: entity)
        }
        return nil
    }

    // MARK: Metadata
    var metadata: DataStoreMetadata? {
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
            var result: DataStore.CompletionResult = .success()
            if let error = error {

                if error._domain == NSCocoaErrorDomain {
                    let code = error._code
                    if code == NSFileReadUnknownError /*256*/{
                        // We can do anything... file system issue, or file path issue
                        logger.error("Could not load datastore \(error)")
                        completionHandler?(.failure(DataStoreError(error)))
                    } else {
                        // https://developer.apple.com/reference/coredata/1535452-validation_error_codes?language=swift
                        if let message = CoreDataStore.message(for: code) {
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
                self.delegate?.dataStoreDidLoad(dataStore)
                logger.verbose("store loaded: \(storeDescription)")
                // .success
            }
            if doNotify {
                Notification(name: .dataStoreLoaded, object:result).post(.dataStore)
                completionHandler?(result)
            }
        }
    }

    static func message(for code: Int) -> String? {
        switch code {
        case NSMigrationMissingMappingModelError: return "migration failed due to missing mapping model."
        case NSMigrationConstraintViolationError: return "migration failed due to a violated uniqueness constraint"
        case NSMigrationCancelledError: return "migration failed due to manual cancellation"
        case NSMigrationMissingSourceModelError: return "migration failed due to missing source data model"
        case NSMigrationMissingMappingModelError: return "migration failed due to missing mapping model"
        case NSMigrationManagerSourceStoreError: return "migration failed due to a problem with the source data store"
        case NSMigrationManagerDestinationStoreError: return "migration failed due to a problem with the destination data store"

        case NSManagedObjectContextLockingError: return "can't acquire a lock in a managed object context"
        case NSPersistentStoreCoordinatorLockingError: return "can't acquire a lock in a persistent store coordinator"

        default: return nil
        }
    }

    /*
     public var entityInfo: [(String, [String])] {
        return self.managedObjectModel.entities.map { ($0.name ?? "", Array($0.attributesByName.keys)) }
    }*/

    public func save(completionHandler: CompletionHandler? = nil) {
        self.viewContext.perform {
            var result: DataStore.CompletionResult = .success()
            do {
                if self.viewContext.hasChanges {
                    try self.viewContext.save()
                }
            } catch {
                result = .failure(DataStoreError(error))
            }
            Notification(name: .dataStoreSaved, object:result).post(.dataStore)
            completionHandler?(result)
        }
    }

    /**
     Drops the data store.
     */
    public func drop(completionHandler: CompletionHandler? = nil) {
        self.viewContext.performAndWait {
            var result: DataStore.CompletionResult = .success()
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
                    Notification(name: .dataStoreDropped, object:result).post(.dataStore)
                    completionHandler?(result)
                    return
                }
                // Do not try to remove /dev/null files
                if store.isTransient {
                    Notification(name: .dataStoreDropped, object:result, userInfo: ["transient": true]).post(.dataStore)
                    completionHandler?(result)
                    return
                }

                // get the store url
                guard let storeURL = store.url, storeURL.isFileURL else {
                    Notification(name: .dataStoreDropped, object:result, userInfo: ["noFile": true]).post(.dataStore)
                    completionHandler?(result)
                    return
                }

                do {
                    // self.persistentStoreCoordinator.remove(store)
                    try self.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: self.storeType.type, options: store.options)
                    // remove the files
                    try self.drop(storeURL: storeURL)

                } catch {
                    result = .failure(DataStoreError(error))
                }
                Notification(name: .dataStoreDropped, object:result).post(.dataStore)
                completionHandler?(result)
            }
        }
    }

    // remove sqlite files
    func drop(storeURL: URL) throws {
        let fileManager = FileManager.default
        try fileManager.removeItemIfExists(at: storeURL)
        try fileManager.removeItemIfExists(atPath: "\(storeURL.absoluteString)-shm")
        try fileManager.removeItemIfExists(atPath: "\(storeURL.absoluteString)-wal")
    }

}

fileprivate extension FileManager {

    func removeItemIfExists(atPath path: String) throws {
        if self.fileExists(atPath: path) {
            try self.removeItem(atPath: path)
        }
    }

    func removeItemIfExists(at url: URL) throws {
        if self.fileExists(at: url) {
            try self.removeItem(at: url)
        }
    }

    func fileExists(at url: URL) -> Bool {
        if url.isFileURL {
            return fileExists(atPath: url.path)
        }
        return false
    }

}

// MARK: Perform Task

extension CoreDataStore {

    func perform(_ type: DataStoreContextType, wait: Bool = false, _ block: @escaping (_ context: DataStoreContext, _ save: @escaping () throws -> Void) -> Void) -> Bool {
        if !isLoaded {
            // CLEAN wait data store loaded and execute perform
            logger.error("Perform action on store but not loaded yet")
            return false
        }
        let userInfo: [String: Any] = ["in": type, "wait": wait]
        Notification(name: .dataStoreWillPerformAction, object: type, userInfo: userInfo).post(.dataStore)

        let blockTask: ((NSManagedObjectContext) -> Void) = { context in
            block(context) { [unowned self] in
                try self.save(context)
            }
            Notification(name: .dataStoreDidPerformAction, object: type, userInfo: userInfo).post(.dataStore)
        }

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
        return true
    }

    func save(_ managedObjectContext: NSManagedObjectContext) throws {
        do {
            try managedObjectContext.save()
        } catch {
            throw DataStoreError(error)
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

    func performBackgroundTask(newContext: Bool = false, _ block: @escaping (NSManagedObjectContext) -> Void) {
        if newContext {
            let context = self.newBackgroundContext()
            context.perform {
                block(context)
            }
        } else {
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
