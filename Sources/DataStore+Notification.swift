//
//  DataStore+Notification.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 08/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension Notification.Name {

    static let dataStoreLoaded = Notification.Name("dataStore.loaded")
    static let dataStoreDropped = Notification.Name("dataStore.dropped")
    static let dataStoreSaved = Notification.Name("dataStore.saved")

}