//
//  CoreDataStoreContext.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 17/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData

// some extension for NSManagedObjectContext
extension NSManagedObjectContext: DataStoreContext {

    public func table(for name: String) -> DataStoreTableInfo? {
        return CoreDataStoreTableInfo(name: name, context: self)
    }

    private func exists(table: String) -> Bool {
        // XXX cache it??, have a list somewhere?
        let description = NSEntityDescription.entity(forEntityName: table, in: self)
        return description != nil
    }

    public func create(in table: String) -> Record? {
        if exists(table: table) {
            return NSEntityDescription.insertNewObject(forEntityName: table, into: self) //as? Record
        }
        return nil
    }

    public func getOrCreate(in table: String, matching predicate: NSPredicate) throws -> Record? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: table)
        request.predicate = predicate
        request.resultType = .managedObjectResultType
        request.fetchLimit = 1

        guard let fetchedObjects = try self.fetch(request) as? [Record] else {
            return create(in: table)
        }
        guard let first = fetchedObjects.first else {
            return create(in: table)
        }
        assert(fetchedObjects.count == 1, "There is more thant one records in table \(table) matching predicate \(predicate)")

        return first
    }

    public func has(in table: String, matching predicate: NSPredicate) throws -> Bool {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: table)
        request.predicate = predicate
        request.resultType = .countResultType

        let result = try self.count(for: request)
        return result != 0
    }

    public func has(record: Record) -> Bool {
        return self.registeredObject(for: record.objectID) != nil
    }

    public func get(in table: String, matching predicate: NSPredicate) throws -> [Record]? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: table)
        request.predicate = predicate
        request.resultType = .managedObjectResultType
        // request.returnsObjectsAsFaults = false

        guard let fetchedObjects = try self.fetch(request) as? [Record] else {
            return nil
        }
        return fetchedObjects
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

    public func update(in table: String, matching predicate: NSPredicate, values: [String : Any]) throws -> Bool {
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

    public func delete(in table: String, matching predicate: NSPredicate? = nil) throws -> Bool {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: table)
        fetch.predicate = predicate
        let request = NSBatchDeleteRequest(fetchRequest: fetch)

        // If we want a list of deleted objects.

        request.resultType = .resultTypeObjectIDs
        guard let batchResult = try self.execute(request) as? NSBatchDeleteResult, let result = batchResult.result as? [NSManagedObjectID] else {
            return false
        }
        let changes = [NSDeletedObjectsKey: result]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])

        return !result.isEmpty

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
        let managedObject = record as NSManagedObject

        if managedObject.managedObjectContext != self {
            let managedObjectInContext = self.object(with: managedObject.objectID)
            self.delete(managedObjectInContext)
        } else {
            self.delete(managedObject)
        }
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

    public var insertedRecords: Set<Record> {
        return self.insertedObjects
    }
    public var updatedRecords: Set<Record> {
        return self.updatedObjects
    }
    public var deletedRecords: Set<Record> {
        return self.deletedObjects
    }
    public var registeredRecords: Set<Record> {
        return self.registeredObjects
    }
    public func refreshAllRecords() {
        self.refreshAllObjects()
    }

    public func fetch(_ request: FetchRequest) throws -> [Record] {
        return try fetch(CoreDataFetchRequest.from(request: request))
    }
    public func count(for request: FetchRequest) throws -> Int {
        return try count(for: CoreDataFetchRequest.from(request: request))
    }

    public func count(in table: String) throws -> Int {
        return try count(for: NSFetchRequest<Record>(entityName: table))
    }

    public func function(_ function: String, in tableName: String, for fieldNames: [String], with predicate: NSPredicate?) throws -> [Double] {

        var expressionsDescription = [NSExpressionDescription]()
        for field in fieldNames {
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
