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

    public func newRecord(table: String) -> Record {
        //swiftlint:disable force_cast
        let record = NSEntityDescription.insertNewObject(forEntityName: table, into: self) as! Record

        // ASK update default field of created record??

        return record
    }

    public func delete(record: Record) {
        self.delete(record as NSManagedObject)
    }

    public func count(for request: FetchRequest) throws -> Int {
        guard let request = request as? NSFetchRequest<NSFetchRequestResult> else {
            logger.warning("")
            return 0
        }

        return try self.count(for: request)
    }

    // TODO batch request
    /*public func execute(request: PersistentStoreRequest) throws {
        guard let request = request as? NSPersistentStoreRequest else {
            logger.warning("")
            return
        }

       try self.execute(request)
    }*/

}

/*
 public protocol PersistentStoreRequest {
 
 var type: PersistentStoreRequestType { get }
 }
 
 public enum PersistentStoreRequestType: UInt {
 case fetch
 case save
 case batchUpdate
 case batchDelete
 }
 
 extension NSPersistentStoreRequest: PersistentStoreRequest {
 
 open var type: PersistentStoreRequestType {
 switch self.requestType {
 case .fetchRequestType: return .fetch
 case .saveRequestType: return .save
 case .batchUpdateRequestType: return .batchUpdate
 case .batchDeleteRequestType: return .batchDelete
 }
 }
 }*/
