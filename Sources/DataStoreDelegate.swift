//
//  DataStoreDelegate.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 22/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

/// A delegate for `DataStore` to receive some event.
public protocol DataStoreDelegate: AnyObject {

    /// The data store will be saved.
    func dataStoreWillSave(_ dataStore: DataStore, context: DataStoreContext)
    /// The data store has been saved.
    func dataStoreDidSave(_ dataStore: DataStore, context: DataStoreContext)
    /// Some object in data has changed.
    func objectsDidChange(dataStore: DataStore, context: DataStoreContext)

    /// The data store will be merged.
    func dataStoreWillMerge(_ dataStore: DataStore, context: DataStoreContext, with: DataStoreContext)
    /// The data store has been merged.
    func dataStoreDidMerge(_ dataStore: DataStore, context: DataStoreContext, with: DataStoreContext)

    /// The data store will be loaded.
    func dataStoreWillLoad(_ dataStore: DataStore)
    /// The data store has beeb loaded.
    func dataStoreDidLoad(_ dataStore: DataStore)
    /// Trying to load an already laoded data store.
    func dataStoreAlreadyLoaded(_ dataStore: DataStore)

}
