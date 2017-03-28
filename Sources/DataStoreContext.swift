//
//  DataStoreContext.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 16/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import Result

/// A context for data task
public protocol DataStoreContext: class {

    /// Create a new record and add it to data store.
    func newRecord(table: String) -> Record

    /// Delete a specific record.
    func delete(record: Record)

    // Count element for request
    func count(for request: FetchRequest) throws -> Int

}

extension DataStoreContext {

    /// Delete records.
    public func delete(records: [Record]) {
        for record in records {
            delete(record: record)
        }
    }

}

/// A type of DataStoreContext
public enum DataStoreContextType {
    case foreground
    case background
}
