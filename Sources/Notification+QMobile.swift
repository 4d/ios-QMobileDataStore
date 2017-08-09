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
    public static let dataStore: NotificationCenter = NotificationCenter.default

}
