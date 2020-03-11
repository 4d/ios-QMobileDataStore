//
//  CoreDataStoreContext.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 17/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData

#if os(macOS)
let useRecordCache = true
#else
let useRecordCache = false
#endif

// some extension for NSManagedObjectContext
extension NSManagedObjectContext: DataStoreContext {

    private func exists(table: String) -> Bool {
        // XXX cache it??, have a list somewhere?
        let description = NSEntityDescription.entity(forEntityName: table, in: self)
        return description != nil
    }

    public func create(in table: String) -> Record? {
        if exists(table: table) {
            return Record(store: NSEntityDescription.insertNewObject(forEntityName: table, into: self))
        }
        return nil
    }

    public func getOrCreate(in table: String, matching predicate: NSPredicate, created: inout Bool) throws -> Record? {
        if useRecordCache,
            let primaryKeyValue = (predicate as? NSComparisonPredicate)?.rightExpression {
            let cache = RecordCache.cache(for: table)
            if let cached = cache.cached(primaryKeyValue) {
                created = false
                return cached
            } else {
                created = true
                let toCache = create(in: table)
                if let toCache = toCache {
                    cache.cache(primaryKeyValue, object: toCache)
                }
                return toCache
            }
        }
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: table)
        request.predicate = predicate
        request.resultType = .managedObjectResultType
        request.fetchLimit = 1

        guard let fetchedObjects = try self.fetch(request) as? [RecordBase] else {
            created = true
            return create(in: table)
        }
        guard let first = fetchedObjects.first else {
             created = true
            return create(in: table)
        }
        created = false
        assert(fetchedObjects.count == 1, "There is more thant one records in table \(table) matching predicate \(predicate)")

        return Record(store: first)
    }

    public func has(in table: String, matching predicate: NSPredicate) throws -> Bool {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: table)
        request.predicate = predicate
        request.resultType = .countResultType

        let result = try self.count(for: request)
        return result != 0
    }

    public func has(record: Record) -> Bool {
        return self.registeredObject(for: record.store.objectID) != nil
    }

    public func get(in table: String, matching predicate: NSPredicate) throws -> [Record]? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: table)
        request.predicate = predicate
        request.resultType = .managedObjectResultType
        // request.returnsObjectsAsFaults = false

        guard let fetchedObjects = try self.fetch(request) as? [RecordBase] else {
            return nil
        }
        return fetchedObjects.map {Record(store: $0)}
    }

    public func insert(in table: String, values: [String: Any]) -> Record? {
        guard let newRecord = create(in: table) else {
            return nil
        }
        for (key, value) in values {
            newRecord.setValue(value, forKey: key)
        }
        return newRecord
    }

    public func update(in table: String, matching predicate: NSPredicate, values: [String: Any]) throws -> Bool {
        let request = NSBatchUpdateRequest(entityName: table)

        request.predicate = predicate
        request.propertiesToUpdate = values

        /*request.resultType = .updatedObjectsCountResultType
        guard let batchResult = try self.execute(request) as? NSBatchUpdateResult, let result = batchResult.result as? Int else {
            return false
        }
        return result != 0 // something has been updated*/

        /*
        request.resultType = .statusOnlyResultType
        guard let batchResult = try self.execute(request) as? NSBatchUpdateResult, let result = batchResult.result as? Bool else {
            return false
        }
        return result
         */

        request.resultType = .updatedObjectIDsResultType
        guard let batchResult = try self.execute(request) as? NSBatchUpdateResult, let result = batchResult.result as? [NSManagedObjectID]  else {
            return false
        }

        //let changes = [NSUpdatedObjectsKey: result]
       // NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])

        return !result.isEmpty // something has been updated
    }

    public func delete(in table: String, matching predicate: NSPredicate? = nil) throws -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: table)
        fetchRequest.predicate = predicate

        // Use simple fetch to get all object. Batch delete is more optimized but test doesn't work
        fetchRequest.includesPropertyValues = false
        guard let fetchedObjects = try self.fetch(fetchRequest) as? [RecordBase] else {
            return -1
        }
        for object in fetchedObjects where !object.isDeleted {
            self.delete(object)
        }
        return fetchedObjects.count

        /*let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        // If we want a list of deleted objects.
        request.resultType = .resultTypeObjectIDs
        guard let batchResult = try self.execute(request) as? NSBatchDeleteResult, let result = batchResult.result as? [NSManagedObjectID] else {
            return -1
        }
        let changes = [NSDeletedObjectsKey: result]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])

        return result.count*/

        // If we want status
        /*
        request.resultType = .resultTypeStatusOnly
        guard let batchResult = try self.execute(request) as? NSBatchDeleteResult, let result = batchResult.result as? Bool else {
            return false
        }
        return result
         */

        // If we want a count, or check that one element has been removed
        /*request.resultType = .resultTypeCount
        guard let batchResult = try self.execute(request) as? NSBatchDeleteResult, let result = batchResult.result as? Int else {
            return false
        }
        return result != 0 // something has been deleted*/
    }

    public func delete(record: Record) {
        let managedObject = record.store as NSManagedObject

        if managedObject.managedObjectContext != self {
            let managedObjectInContext = self.object(with: managedObject.objectID)
            self.delete(managedObjectInContext)
        } else {
            self.delete(managedObject)
        }
    }

    public func refresh(_ record: Record, mergeChanges flag: Bool) {
        self.refresh(record.store, mergeChanges: flag)
    }
    public func detectConflicts(for record: Record) {
        self.detectConflicts(for: record.store)
    }

    public var type: DataStoreContextType {
        switch self.concurrencyType {
        case .mainQueueConcurrencyType:
            return .foreground
        case .privateQueueConcurrencyType:
            return .background
        default:
            assertionFailure("deprecated type \(self.concurrencyType)")
            return .background
        }
    }

    /// Commit data store context modifications.
    public func commit() throws {
        do {
            try self.save()
        } catch {
            throw DataStoreError.error(from: error)
        }
    }

    /// Perform an operation on context queue and wait
    public func perform(wait: Bool, _ block: @escaping () -> Void) {
        if wait {
            self.performAndWait(block)
        } else {
            self.perform(block)
        }
    }

    public func performOnChildContext(_ type: DataStoreContextType, wait: Bool, _ block: @escaping (DataStoreContext) -> Void) {
        let childContext = NSManagedObjectContext(concurrencyType: type.concurrencyType)
        childContext.parent = self
        childContext.persistentStoreCoordinator = self.persistentStoreCoordinator

        childContext.perform(wait: wait) {
            block(childContext)
        }
    }

    public var parentContext: DataStoreContext? {
        get {
            return self.parent // protocol do not use Self to not force generic
        }
        set {
            if let moc = newValue as? NSManagedObjectContext {
                self.parent = moc
            } else {
                self.parent = nil
            }
        }
    }

    public var insertedRecords: [Record] {
        return self.insertedObjects.map { Record(store: $0) }
    }
    public var updatedRecords: [Record] {
        return self.updatedObjects.map { Record(store: $0) }
    }
    public var deletedRecords: [Record] {
        return self.deletedObjects.map { Record(store: $0) }
    }
    public var registeredRecords: [Record] {
        return self.registeredObjects.map { Record(store: $0) }
    }
    public func refreshAllRecords() {
        self.refreshAllObjects()
    }

    public func fetch(_ request: FetchRequest) throws -> [Record] {
        return try fetch(CoreDataFetchRequest.from(request: request)).map { Record(store: $0) }
    }
    public func count(for request: FetchRequest) throws -> Int {
        return try count(for: CoreDataFetchRequest.from(request: request))
    }

    public func count(in table: String) throws -> Int {
        return try count(for: NSFetchRequest<RecordBase>(entityName: table))
    }

    public func function(_ function: String, in tableName: String, for fieldNames: [String], with predicate: NSPredicate?) throws -> [Double] {

        var expressionsDescription = [NSExpressionDescription]()
        for field in fieldNames where !field.isEmpty {
            let expression = NSExpression(forKeyPath: field)
            let expressionDescription = NSExpressionDescription()
            expressionDescription.expression = NSExpression(forFunction: function, arguments: [expression])
            expressionDescription.expressionResultType = NSAttributeType.doubleAttributeType
            expressionDescription.name = field
            expressionsDescription.append(expressionDescription)
        }

        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest<NSFetchRequestResult>(entityName: tableName)
        fetchRequest.propertiesToFetch = expressionsDescription
        fetchRequest.resultType = NSFetchRequestResultType.dictionaryResultType

        var resultValue = [Double]()

        let results = try self.fetch(fetchRequest) as? [[String: Any]]

        for result in results ?? [] {
            for field in fieldNames {
                let value = result[field] as? Double ?? 0
                resultValue.append(value)
            }
        }
        return resultValue
    }

    public func function(_ function: String, request: FetchRequest, for fieldNames: [String]) throws -> [Double] {
        return try self.function(function, in: request.tableName, for: fieldNames, with: request.predicate)
    }

    // MARK: Structures
    public var tablesInfo: [DataStoreTableInfo] {
        guard let entities = self.persistentStoreCoordinator?.managedObjectModel.entities else {
            return []
        }
        return entities.filter { $0.name != nil }.map { CoreDataStoreTableInfo(entity: $0) }
    }

    public func tableInfo(for name: String) -> DataStoreTableInfo? {
        guard let entities = self.persistentStoreCoordinator?.managedObjectModel.entities else {
            return nil
        }
        for entity in entities where entity.name == name {
            return CoreDataStoreTableInfo(entity: entity)
        }
        return nil
    }

}

extension DataStoreChangeType {

    var coreData: String {
        switch self {
        case .inserted: return NSInsertedObjectsKey
        case .deleted: return NSDeletedObjectsKey
        case .updated: return NSUpdatedObjectsKey
        }
    }
}
extension DataStoreContextType {
    var concurrencyType: NSManagedObjectContextConcurrencyType {
        switch self {
        case .foreground:
            return .mainQueueConcurrencyType
        case .background:
            return .privateQueueConcurrencyType
        }
    }
}

extension DispatchQueue {
    class var currentLabel: String {
        return String(validatingUTF8: __dispatch_queue_get_label(nil)) ?? ""
    }

    class var isManagedObjectContext: Bool {
        let label = DispatchQueue.currentLabel
        return label.contains("NSManagedObjectContext")
    }
}

// MARK: - cache used to speed up batch import
private class RecordCache {

    static var caches: [String: RecordCache] = [:]
    static func cache(for tableName: String) -> RecordCache {
        if let cache = caches[tableName] {
            return cache
        }
        let cache = RecordCache(name: tableName)
        caches[tableName] = cache
        return cache
    }

    fileprivate var cache: NSCache<NSExpression, Record>

    init(name: String) {
        cache = NSCache<NSExpression, Record>()
        cache.name = name
    }

    func cached(_ expression: NSExpression) -> Record? {
        return cache.object(forKey: expression)
    }
    func cache(_ expression: NSExpression, object: Record) {
        cache.setObject(object, forKey: expression)
    }
}
