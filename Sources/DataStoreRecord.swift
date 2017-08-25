//
//  Record.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 14/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

/// A Record, parent class of all business object.
//public typealias Record = RecordBase

public protocol DataStoreRecord: NSObjectProtocol, Hashable, Equatable {
}

// XXX Record could be a class if core data model class generation allow a root class

public class Record: NSObject {

    public var store: RecordBase // DataStoreRecord

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

    open var tableInfo: DataStoreTableInfo {
        return store.tableInfo
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

    // Hashable,
    public override var hashValue: Int {
        return store.hashValue
    }
    // Equatable
    public static func == (lhs: Record, rhs: Record) -> Bool {
        return lhs.store == rhs.store
    }

    // MARK: override KVO
    public override func value(forUndefinedKey key: String) -> Any? {
         return store.value(forKey:key)
    }

    public override func value(forKey key: String) -> Any? {
        return store.value(forKey: key)
    }

    public override func value(forKeyPath keyPath: String) -> Any? {
        return store.value(forKeyPath: keyPath.replacingOccurrences(of: " ", with: ""))
    }

    public override func setValue(_ value: Any?, forKey key: String) {
        store.setValue(value, forKey: key)
    }

    public override func setValuesForKeys(_ keyedValues: [String : Any]) {
          store.setValuesForKeys(keyedValues)
    }

    public override func setNilValueForKey(_ key: String) {
        store.setNilValueForKey(key)
    }
    public override func setValue(_ value: Any?, forUndefinedKey key: String) {
        store.setValue(value, forUndefinedKey: key)
    }

    public override func dictionaryWithValues(forKeys keys: [String]) -> [String : Any] {
        return store.dictionaryWithValues(forKeys: keys)
    }

    public override func setValue(_ value: Any?, forKeyPath keyPath: String) {
        store.setValue(value, forKeyPath: keyPath)
    }

}
