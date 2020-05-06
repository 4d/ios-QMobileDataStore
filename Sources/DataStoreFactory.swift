//
//  DataStoreFactory.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 28/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

/// Object which contain the data store used.
public class DataStoreFactory {

    /// The data store. By default : core data store
    public static var dataStore: DataStore = CoreDataStore.default

}

// MARK: events
extension DataStoreFactory {

    /// Observe notification from data store
    /// When registering for a notification, the opaque observer that is returned should be stored so it can be removed later using `unobserve` method.
    public static func observe(_ name: Notification.Name, queue: OperationQueue? = nil, using: @escaping (Notification) -> Void) -> NSObjectProtocol {
        return NotificationCenter.dataStore.addObserver(forName: name, object: nil, queue: queue, using: using)
    }

    /// Unobserve notification from data store
    public static func unobserve(_ observer: NSObjectProtocol) {
        NotificationCenter.dataStore.removeObserver(observer)
    }

    /// Unobserve notification from data store
    public static func unobserve(_ observers: [NSObjectProtocol]) {
        for observer in observers {
            unobserve(observer)
        }
    }

    /// When registering for a notification, the opaque observer that is returned should be stored so it can be removed later using `unobserve` method.
    public static func onLoad(queue: OperationQueue? = nil, using: @escaping (Notification) -> Void) -> NSObjectProtocol {
        return observe(.dataStoreLoaded, queue: queue, using: using)
    }

    /// When registering for a notification, the opaque observer that is returned should be stored so it can be removed later using `unobserve` method.
    public static func onDrop(queue: OperationQueue? = nil, using: @escaping (Notification) -> Void) -> NSObjectProtocol {
        return observe(.dataStoreDropped, queue: queue, using: using)
    }

    /// When registering for a notification, the opaque observer that is returned should be stored so it can be removed later using `unobserve` method.
    public static func onSave(queue: OperationQueue? = nil, using: @escaping (Notification) -> Void) -> NSObjectProtocol {
        return observe(.dataStoreSaved, queue: queue, using: using)
    }

}
