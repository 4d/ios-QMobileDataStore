//
//  DataStoreDelegate.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 22/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

/// A delegate for `DataStore`
public protocol DataStoreDelegate: class {

    func dataStoreWillSave(_ dataStore: DataStore)
    func dataStoreDidSave(_ dataStore: DataStore)
    func objectsDidChange(dataStore: DataStore)

    func dataStoreWillLoad(_ dataStore: DataStore)
    func dataStoreDidLoad(_ dataStore: DataStore)
    func dataStoreAlreadyLoaded(_ dataStore: DataStore)
}
