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
        if let newRecord = create(in: table) {
            for (key, value) in values {
                newRecord.setValue(value, forKey: key)
            }
            return newRecord
        }
        return nil
    }

    public func update(in table: String, matching predicate: NSPredicate, values: [String: Any]) throws -> Bool {
        let request = NSBatchUpdateRequest(entityName: table)
        request.predicate = predicate
        request.propertiesToUpdate = values
        request.resultType = .updatedObjectsCountResultType

        guard let batchResult = try self.execute(request) as? NSBatchUpdateResult, let result = batchResult.result as? Int else {
            return false
        }
        return result != 0 // something has been updated
    }

    public func delete(in table: String, matching predicate: NSPredicate) throws -> Bool {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: table)
        fetch.predicate = predicate
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        request.resultType = .resultTypeCount

        guard let batchResult = try self.execute(request) as? NSBatchDeleteResult, let result = batchResult.result as? Int else {
            return false
        }
        return result != 0 // something has been deleted
    }

    public func delete(record: Record) {
        // CLEAN will fald is not good table, use predicate?
        self.delete(record as NSManagedObject)
    }

}
