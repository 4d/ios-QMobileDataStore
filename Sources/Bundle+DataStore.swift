//
//  Bundle+DataStore.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 30/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import Prephirences

extension Bundle {

    /// Bundle used to load data store data. By default main bundle
    @nonobjc public static var dataStore: Bundle = .main
    /// Key used to get data store file name. By default 'QDataStore'
    @nonobjc public static var dataStoreKey: String = "QDataStore"

    /// Datastore model name in bundle.
    @nonobjc public static var dataStoreModelName: String? {
        return Bundle.dataStore[Bundle.dataStoreKey] as? String
    }

}
