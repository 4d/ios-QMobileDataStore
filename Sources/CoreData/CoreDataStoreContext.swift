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

    public func exists(table: String) -> Bool {
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

        request.resultType = .updatedObjectsCountResultType
        guard let batchResult = try self.execute(request) as? NSBatchUpdateResult, let result = batchResult.result as? Int else {
            return false
        }
        return result != 0 // something has been updated

        /*
        request.resultType = .statusOnlyResultType
        guard let batchResult = try self.execute(request) as? NSBatchUpdateResult, let result = batchResult.result as? Bool else {
            return false
        }
        return result
         */
        /*
        request.resultType = .updatedObjectIDsResultType
        guard let batchResult = try self.execute(request) as? NSBatchUpdateResult, let result = batchResult.result as? [NSManagedObjectID]  else {
            return false
        }
        return !result.isEmpty // something has been updated
        */
    }

    public func delete(in table: String, matching predicate: NSPredicate? = nil) throws -> Bool {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: table)
        fetch.predicate = predicate
        let request = NSBatchDeleteRequest(fetchRequest: fetch)

        // If we want a list of deleted objects.
        /*
        request.resultType = .resultTypeObjectIDs
        guard let batchResult = try self.execute(request) as? NSBatchDeleteResult, let result = batchResult.result as? [NSManagedObjectID] else {
            return false
        }
        return !result.isEmpty
         */

        // If we want status
        /*
        request.resultType = .resultTypeStatusOnly
        guard let batchResult = try self.execute(request) as? NSBatchDeleteResult, let result = batchResult.result as? Bool else {
            return false
        }
        return result
         */

        // If we want a count, or check that one element has been removed
        request.resultType = .resultTypeCount
        guard let batchResult = try self.execute(request) as? NSBatchDeleteResult, let result = batchResult.result as? Int else {
            return false
        }
        return result != 0 // something has been deleted
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
}
