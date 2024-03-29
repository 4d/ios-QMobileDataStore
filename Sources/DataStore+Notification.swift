//
//  DataStore+Notification.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 08/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

public extension Notification.Name {

    static let dataStoreLoaded = Notification.Name("dataStore.loaded")
    static let dataStoreDropped = Notification.Name("dataStore.dropped")
    static let dataStoreSaved = Notification.Name("dataStore.saved")

    static let dataStoreWillPerformAction = Notification.Name("dataStore.willPerformAction")
    static let dataStoreDidPerformAction = Notification.Name("dataStore.didPerformAction")

    static let dataStoreWillMerge = Notification.Name("dataStore.willMerge")
    static let dataStoreDidMerge = Notification.Name("dataStore.didMerge")
}

extension DataStore {

    static var loaded: Notification.Name {
        return Notification.Name .dataStoreLoaded
    }
    /*static let dropped = Notification.Name("dataStore.dropped")
    static let saved = Notification.Name("dataStore.saved")

    static let willPerformAction = Notification.Name("dataStore.willPerformAction")
    static let didPerformAction = Notification.Name("dataStore.didPerformAction")

    static let willMerge = Notification.Name("dataStore.willMerge")
    static let didMerge = Notification.Name("dataStore.didMerge")*/
}
