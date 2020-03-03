//
//  Record.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 14/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

// XXX Record could be a class if core data model class generation allow a root class
protocol DataStoreRecord: NSObjectProtocol, Hashable {}

public struct PendingRecord {
   /* enum PendingError: Error {

    }*/
    public static var pendingRecords = Set<Record>()
}

/// A Record, parent class of all business object.
public class Record: NSObject {

    // CLEAN merge it with one from api, set this one in api, its a datastore constrains
    @nonobjc public static var reservedSwiftVars: [String] =  ["objectID", "description", "shortDescription", "isDeleted", "isUpdated", "isInserted", "hasChanges", "hasPersistentChangedValues", "entity", "isFault"]

    public var store: RecordBase // DataStoreRecord

    /// Store record created by relation.
    public static var pendingRecords = Set<Record>()
    public var pending: Bool? {
        didSet {
            if oldValue != pending, let pending = pending { // has change
                if pending {
                    PendingRecord.pendingRecords.insert(self)
                } else {
                    if oldValue != nil {
                        PendingRecord.pendingRecords.remove(self)
                    }
                }
            }
        }
    }

    init(store: RecordBase) {
        self.store = store
    }

    @nonobjc init?(store: RecordBase?) {
        guard let store = store else {
            return nil
        }
        self.store = store
    }

    // MARK: remap to store object
    open subscript(key: String) -> Any? {
        get {
            return store.value(forKey: key)
        }
        set {
            if store.hasKey(key) {
                store.setValue(newValue, forKey: key)
            } /*else {
             // not key value coding-compliant for the key
             }*/
        }
    }
    open var tableName: String {
        return store.entity.name ?? store.entity.managedObjectClassName
    }
    open var tableInfo: DataStoreTableInfo {
        return store.tableInfo
    }

    open override var description: String {
        return self.store.description
    }
    open override var debugDescription: String {
        return self.store.debugDescription
    }

    open func hasKey(_ key: String) -> Bool {
        return self.store.hasKey(key)
    }

    open var predicate: NSPredicate { // XXX maybe remove, let access using store
        return self.store.predicate
    }
    open var predicateForBatch: NSPredicate { // XXX maybe remove, let access using store
        return self.store.predicateForBatch
    }

    open func validateForInsert() throws {
        do {
            try store.validateForInsert()
        } catch {
            throw DataStoreError(error)
        }
    }

    open func validateForUpdate() throws {
        do {
            try store.validateForUpdate()
        } catch {
            throw DataStoreError(error)
        }
    }

    open func validateForDelete() throws {
        do {
            try store.validateForDelete()
        } catch {
            throw DataStoreError(error)
        }
    }

    open var context: DataStoreContext? {
        return store.managedObjectContext
    }

    open var isInserted: Bool {
        return store.isInserted
    }

    open var isUpdated: Bool {
        return store.isUpdated
    }

    open var isDeleted: Bool {
        return store.isDeleted
    }

    open var hasPersistentChangedValues: Bool {
        return store.hasPersistentChangedValues
    }

    // Hashable,
    public override var hash: Int {
        return store.hashValue
    }

    // Equatable
    public static func == (lhs: Record, rhs: Record) -> Bool { // swiftlint:disable:this nsobject_prefer_isequal
        return lhs.store == rhs.store
    }

    // MARK: override KVO
    public override func value(forUndefinedKey key: String) -> Any? {
         return store.value(forKey: key)
    }

    public override func value(forKey key: String) -> Any? {
        if Record.reservedSwiftVars.contains(key) {
            if hasKey("\(key)_") {
                return store.value(forKey: "\(key)_")   //" XXX Same rules in api, have to place for this rules is bad
            } else {
                return store.value(forKey: key)
            }
        } else {
            return store.value(forKey: key)
        }
    }

    public override func value(forKeyPath keyPath: String) -> Any? {
        let keyPath = keyPath.replacingOccurrences(of: " ", with: "") // simple conversion, not really the one done in api, check coherence...
        if Record.reservedSwiftVars.contains(keyPath) {
            return store.value(forKeyPath: "\(keyPath)_")
        } else {
            return store.value(forKeyPath: keyPath)
        }
    }

    public override func setValue(_ value: Any?, forKey key: String) {
        //if Record.reservedSwiftVars.contains(key) {
         //   store.setValue(value, forKey: "\(key)_") // XXX Same rules in api, have to place for this rules is bad
       // } else {
            store.setValue(value, forKey: key)
       // }
    }

    public override func setValuesForKeys(_ keyedValues: [String: Any]) {
          store.setValuesForKeys(keyedValues)
    }

    public override func setNilValueForKey(_ key: String) {
        store.setNilValueForKey(key)
    }
    public override func setValue(_ value: Any?, forUndefinedKey key: String) {
        store.setValue(value, forUndefinedKey: key)
    }

    public override func dictionaryWithValues(forKeys keys: [String]) -> [String: Any] {
        return store.dictionaryWithValues(forKeys: keys)
    }

    public override func setValue(_ value: Any?, forKeyPath keyPath: String) {
        store.setValue(value, forKeyPath: keyPath)
    }

}

/*func == (lhs: Record, rhs: Record) -> Bool {
    return lhs.store == rhs.store
}*/
