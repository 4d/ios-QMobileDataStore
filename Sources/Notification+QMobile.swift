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

}

extension NotificationCenter {

    /// Notification center used by data store. Default is `.default`
    public static var dataStore: NotificationCenter = NotificationCenter.default

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
