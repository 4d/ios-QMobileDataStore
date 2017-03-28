//
//  Globals.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 28/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

// Here come CoreData dependency to break if needed
import CoreData

public let dataStore: DataStore = CoreDataStore.default

public typealias RecordBase = NSManagedObject
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

    open func hasKey(_ key: String) -> Bool {
        return self.entity.propertiesByName[key] != nil // CLEAN optimize how to known if record KVC compliant to key
    }

    open override func value(forUndefinedKey key: String) -> Any? {
        assertionFailure("Undefined key for '\(key) for record \(self)")
        return nil
    }

}
