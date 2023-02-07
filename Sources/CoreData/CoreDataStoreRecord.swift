//
//  RecordBase.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 29/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData

public typealias RecordBase = NSManagedObject

// let kPendingKey = "qmobile_pending"
extension NSManagedObject: DataStoreRecord {

    public func getPending() -> Bool? {
        /*if self.hasKey(kPendingKey) {
         return self.value(forKey: kPendingKey) as? Bool
         }*/
        guard let context = self.managedObjectContext else {
            logger.debug("No context when pending")
            return nil
        }
        return context._pendingRecords.info[self.objectID]
    }

    public func setPending(_ newValue: Bool?) {
        /* if self.hasKey(kPendingKey) {
         setValue(newValue, forKey: kPendingKey)
         } else {*/
        guard let context = self.managedObjectContext else {
            logger.debug("No context when setting pending")
            return
        }
        let pendingRecords = context._pendingRecords
        let objectID = self.objectID
        let oldValue = pendingRecords.info[objectID]
        pendingRecords.info[objectID] = newValue
        /* }*/

        // didSet
        pendingRecords.manage(record: self, oldValue: oldValue, newValue: newValue)
    }
}

class PendingRecord: NSObject { // create objc class explicitly and avoid singleton

    var info: [NSManagedObjectID: Bool] = [:]
    var pendingRecords = NSMutableSet()

    func manage(record: NSManagedObject, oldValue: Bool?, newValue: Bool?) {
        if oldValue != newValue { // has change
            if let pending = newValue, pending {
                /*if pendingRecords.count%100 == 0 {
                 print("🎾 will insert \(record) into list of size \(pendingRecords.count)")
                 }*/
                pendingRecords.add(record)
            } else {
                if oldValue != nil {
                    /*if pendingRecords.count%100 == 0 {
                     print("🌶 will remove \(record) from list of size \(pendingRecords.count)")
                     }*/
                    pendingRecords.remove(record)
                }
            }
        }
    }

    func consume() -> [Record] {
        let pendingRecords = Array(self.pendingRecords)
        self.pendingRecords.removeAllObjects()
        logger.debug("Record to not persists: \(pendingRecords.count)")
        return pendingRecords.compactMap { $0 as? NSManagedObject }.map { Record(store: $0) }
    }

}

// MARK: record base
extension RecordBase {

    /// Access record attribute value using string key
    public subscript(key: String) -> Any? {
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

    public var tableInfo: DataStoreTableInfo {
        return CoreDataStoreTableInfo(entity: self.entity)
    }

    public func hasKey(_ key: String) -> Bool {
        return self.entity.propertiesByName[key] != nil // CLEAN optimize how to known if record KVC compliant to key
    }

    open override func value(forUndefinedKey key: String) -> Any? {
        if !key.isEmpty {

            // XXX here maybe map with other field, like mapped field, renamed field for core data
            // for instance look into entity fields the keyMapping userInfo

            // assertionFailure("Undefined field '\(key)' for record \(self). Check your binding in storyboard.")
        }
        return nil
    }

    public var predicate: NSPredicate {
        return NSPredicate(format: "SELF = %@", objectID)
    }
    public var predicateForBatch: NSPredicate {
        return NSPredicate(format: "objectID = %@", objectID)
    }

    /*open func willSave() {
         // can set here timestamps to know objec =t with modification since last SyNCHRO
    }*/

}
