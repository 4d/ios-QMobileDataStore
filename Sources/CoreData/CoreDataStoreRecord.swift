//
//  RecordBase.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 29/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData

import Result

public typealias RecordBase = NSManagedObject

extension NSManagedObject: DataStoreRecord {

}

public extension NSManagedObjectContext {

    public static var `default`: NSManagedObjectContext {
        return CoreDataStore.default.viewContext
    }

    public static func newBackgroundContext() -> NSManagedObjectContext {
        return CoreDataStore.default.newBackgroundContext()
    }

    /*fileprivate struct Key {
     static let coreDataStore = UnsafeRawPointer(bitPattern: Selector(("coreDataStore")).hashValue)
     }
     internal (set) var coreDataStore: CoreDataStore? {
     get {
     if let obj = objc_getAssociatedObject(self, Key.coreDataStore) as? CoreDataStore {
     return obj
     }
     return nil
     }
     set {
     objc_setAssociatedObject(self, Key.coreDataStore, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
     }
     }*/

}

// MARK: record base
extension RecordBase {

    /// Access record attribute value using string key
    open subscript(key: String) -> Any? {
        get {
            return self.value(forKey: key)
        }
        set {
            if hasKey(key) {
                self.setValue(newValue, forKey: key)
            } /*else {
             // not key value coding-compliant for the key
             }*/
        }
    }

    open var tableInfo: DataStoreTableInfo {
        return CoreDataStoreTableInfo(entity: self.entity)
    }

    open func hasKey(_ key: String) -> Bool {
        return self.entity.propertiesByName[key] != nil // CLEAN optimize how to known if record KVC compliant to key
    }

    open override func value(forUndefinedKey key: String) -> Any? {
        if !key.isEmpty {

            // XXX here maybe map with other field, like mapped field, renamed field for core data
            // for instance look into entity fields the keyMapping userInfo

            assertionFailure("Undefined field '\(key)' for record \(self). Check your binding in storyboard.")
        }
        return nil
    }

    open var predicate: NSPredicate {
        return NSPredicate(format: "SELF = %@", objectID)
    }
    open var predicateForBatch: NSPredicate {
        return NSPredicate(format: "objectID = %@", objectID)
    }

    /*open func willSave() {
         // can set here timestamps to know objec =t with modification since last SyNCHRO
    }*/

}
