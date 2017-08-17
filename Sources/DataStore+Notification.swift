//
//  DataStore+Notification.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 08/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

public extension Notification.Name {

    public static let dataStoreLoaded = Notification.Name("dataStore.loaded")
    public static let dataStoreDropped = Notification.Name("dataStore.dropped")
    public static let dataStoreSaved = Notification.Name("dataStore.saved")

    public static let dataStoreWillPerformAction = Notification.Name("dataStore.willPerformAction")
    public static let dataStoreDidPerformAction = Notification.Name("dataStore.didPerformAction")

    public static let dataStoreWillMerge = Notification.Name("dataStore.willMerge")
    public static let dataStoreDidMerge = Notification.Name("dataStore.didMerge")
}
