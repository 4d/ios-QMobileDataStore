//
//  Notification+QMobile.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 08/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension Notification {

    public func post(_ center: NotificationCenter = .default) {
        center.post(self)
    }

    public var error: Error? {
        return userInfo?[NSUnderlyingErrorKey] as? Error
    }

}

extension NotificationCenter {

    /// Notification center used by data store. Default is `.default`
    public static var dataStore: NotificationCenter = NotificationCenter.default

    /// Add observer for multiple names.
    public func addObservers(_ observer: Any, selector aSelector: Selector, names aNames: [NSNotification.Name], object anObject: Any?) {
        for name in aNames {
            addObserver(observer, selector: aSelector, name: name, object: anObject)
        }
    }
}

extension Notification {

    /// Return objects in notification
    subscript(changeType: DataStoreChangeType) -> [Record]? {
        guard let info = self.userInfo?[changeType.coreData], let set = info as? Set<RecordBase> else {
            return nil
        }
        return set.map { Record(store: $0) }
    }

}
