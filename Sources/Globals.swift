//
//  Globals.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 28/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

// Here come CoreData dependency to break if needed
import CoreData

public let dataStore: DataStore = CoreDataStore.default

// Configuration
import Prephirences

extension Bundle {

    /// Bundle used to load data store data. By default main bundle
    @nonobjc public static var dataStore: Bundle = .main
    /// Key used to get data store file name. By default 'CFBundleName'
    @nonobjc public static var dataStoreKey: String = "CFBundleName"

    @nonobjc public static var dataStoreModelName: String? {
        return Bundle.dataStore[Bundle.dataStoreKey] as? String
    }

}
